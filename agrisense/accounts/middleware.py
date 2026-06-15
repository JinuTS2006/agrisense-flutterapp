import traceback
import os

class ErrorLoggingMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        return self.get_response(request)

    def process_exception(self, request, exception):
        tb = traceback.format_exc()
        # Ensure a writable logs directory inside the project root
        try:
            from django.conf import settings
            logs_dir = os.path.join(settings.BASE_DIR, "logs")
            os.makedirs(logs_dir, exist_ok=True)
            log_path = os.path.join(logs_dir, "django_error_log.txt")
            with open(log_path, "a", encoding="utf-8") as f:
                f.write(f"=== EXCEPTION AT {request.path} ===\n{tb}\n\n")
            # Also output to stdout so Render captures it in its logs
            print(f"[ERROR LOG] Exception at {request.path}:\n{tb}")
        except Exception as write_err:
            print(f"Error logging middleware failed to write: {write_err}")
        return None
