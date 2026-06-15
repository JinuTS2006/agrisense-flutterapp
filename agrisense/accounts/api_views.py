from rest_framework import views, status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from django.conf import settings as django_settings
from .models import User
from farmer.models import FarmerProfile
from buyer.models import BuyerProfile
from delivery.models import DeliveryAgentProfile
from .serializers import UserSerializer, RegisterSerializer

class LoginAPIView(views.APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        username = request.data.get("username")
        password = request.data.get("password")

        user = authenticate(username=username, password=password)
        if user:
            refresh = RefreshToken.for_user(user)
            return Response({
                "access": str(refresh.access_token),
                "refresh": str(refresh),
                "user": UserSerializer(user).data
            })
        return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)

class RegisterAPIView(views.APIView):
    permission_classes = [AllowAny]

    def post(self, request, role):
        if role not in ["farmer", "buyer", "delivery"]:
            return Response({"error": "Invalid role"}, status=status.HTTP_400_BAD_REQUEST)

        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            data = serializer.validated_data
            user = User.objects.create_user(
                username=data['username'],
                email=data.get('email', ''),
                password=data['password'],
                first_name=data['full_name'],
                phone=data.get('phone_number', ''),
                role=role
            )

            city = data.get('city', '')
            state = data.get('state', '')

            if role == "farmer":
                FarmerProfile.objects.create(user=user, city=city, state=state)
            elif role == "buyer":
                BuyerProfile.objects.create(user=user, city=city, state=state)
            elif role == "delivery":
                DeliveryAgentProfile.objects.create(user=user, city=city, state=state)

            refresh = RefreshToken.for_user(user)
            return Response({
                "message": f"{role.capitalize()} registration successful!",
                "access": str(refresh.access_token),
                "refresh": str(refresh),
                "user": UserSerializer(user).data
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ChatbotAPIView(views.APIView):
    """
    Multi-language agricultural chatbot powered by Google Gemini.
    POST: { "message": "...", "language": "English", "conversation_history": [...] }
    Returns: { "reply": "..." }
    """
    permission_classes = [IsAuthenticated]

    LANGUAGE_MAP = {
        "English": "English",
        "Hindi": "Hindi (हिंदी)",
        "Tamil": "Tamil (தமிழ்)",
        "Telugu": "Telugu (తెలుగు)",
        "Malayalam": "Malayalam (മലയാളം)",
        "Kannada": "Kannada (ಕನ್ನಡ)",
        "Bengali": "Bengali (বাংলা)",
        "Marathi": "Marathi (मराठी)",
        "Spanish": "Spanish (Español)",
        "French": "French (Français)",
        "Arabic": "Arabic (العربية)",
    }

    def post(self, request):
        message = request.data.get("message", "").strip()
        language = request.data.get("language", "English")
        conversation_history = request.data.get("conversation_history", [])

        if not message:
            return Response({"error": "Message is required."}, status=status.HTTP_400_BAD_REQUEST)

        api_key = getattr(django_settings, 'GEMINI_API_KEY', '')

        if not api_key:
            reply = self._get_mock_response(message, language)
            return Response({"reply": reply})

        try:
            import google.generativeai as genai
            genai.configure(api_key=api_key)

            lang_name = self.LANGUAGE_MAP.get(language, "English")
            system_prompt = f"""You are AgriBot, a helpful AI assistant for Agrisense — an agricultural marketplace platform.
You assist farmers, buyers, and delivery agents with agriculture-related questions.

Your areas of expertise include:
- Crop selection and recommendations based on soil, climate, and season
- Farming best practices and techniques
- Market prices and trading tips for agricultural products
- Pest and disease identification and remedies
- Fertilizer and irrigation advice
- Weather-based farming decisions
- Order and delivery queries on the Agrisense platform

IMPORTANT: You MUST respond ONLY in {lang_name}. Even if the user writes in another language, always reply in {lang_name}.
Keep your responses concise, friendly, and practical. Use simple language that farmers and rural users can understand.
"""

            model = genai.GenerativeModel(
                model_name='gemini-2.5-flash',
                system_instruction=system_prompt
            )

            # Build conversation history for context
            history = []
            for msg in conversation_history[-10:]:  # keep last 10 messages for context
                role = "user" if msg.get("isUser") else "model"
                history.append({
                    "role": role,
                    "parts": [msg.get("text", "")]
                })

            chat = model.start_chat(history=history)
            response = chat.send_message(message)
            reply = response.text

        except Exception as e:
            import traceback
            error_msg = str(e)
            print(f"[ChatbotAPIView ERROR] {traceback.format_exc()}")
            return Response({"reply": f"⚠️ AgriBot error: {error_msg}"})

        return Response({"reply": reply})

    def _get_mock_response(self, message, language):
        """Fallback response when Gemini API is not configured."""
        responses = {
            "English": f"Hello! I'm AgriBot 🌱. I'm here to help with farming, crop advice, and market questions. To unlock full AI responses, please add your Gemini API key in settings.py. You asked: '{message}'",
            "Hindi": f"नमस्ते! मैं AgriBot हूँ 🌱। खेती और फसल संबंधी सवालों में मदद के लिए यहाँ हूँ। पूरी AI सुविधा के लिए settings.py में Gemini API key जोड़ें।",
            "Tamil": f"வணக்கம்! நான் AgriBot 🌱. விவசாயம் மற்றும் பயிர் ஆலோசனைக்கு நான் இங்கே இருக்கிறேன். முழு AI அம்சங்களுக்கு settings.py இல் Gemini API key சேர்க்கவும்.",
            "Malayalam": f"നമസ്കാരം! ഞാൻ AgriBot 🌱 ആണ്. കൃഷി, വിള ഉപദേശം, വിപണി ചോദ്യങ്ങൾ എന്നിവയ്ക്ക് ഞാൻ ഇവിടെ ഉണ്ട്. പൂർണ AI ഉത്തരങ്ങൾക്ക് settings.py-ൽ Gemini API key ചേർക്കുക.",
        }
        return responses.get(language, responses["English"])


class DiagnosticLogAPIView(views.APIView):
    permission_classes = []
    def get(self, request):
        import os
        from django.core.mail import send_mail
        from django.conf import settings
        try:
            send_mail(
                subject="Render SMTP Diagnostic Test",
                message="Testing connection...",
                from_email=settings.EMAIL_HOST_USER,
                recipient_list=[settings.EMAIL_HOST_USER],
                fail_silently=False
            )
            return Response({"status": "success", "message": "Email sent successfully!"})
        except Exception as e:
            import traceback
            return Response({"status": "error", "error": str(e), "traceback": traceback.format_exc()})
