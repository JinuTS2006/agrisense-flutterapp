import traceback
import os

class ErrorLoggingMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        return self.get_response(request)

    def process_exception(self, request, exception):
        tb = traceback.format_exc()
        try:
            log_path = "django_error_log.txt"
            with open(log_path, "a", encoding="utf-8") as f:
                f.write(f"=== EXCEPTION AT {request.path} ===\n{tb}\n\n")
        except Exception as write_err:
            print(f"Error logging middleware failed to write: {write_err}")
        return None
