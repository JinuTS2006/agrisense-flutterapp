import traceback
import os

class ErrorLoggingMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        try:
            return self.get_response(request)
        except Exception as e:
            tb = traceback.format_exc()
            try:
                # Write to a file in a writable directory.
                # In Render, the current directory is writable.
                log_path = "django_error_log.txt"
                with open(log_path, "a", encoding="utf-8") as f:
                    f.write(f"=== EXCEPTION AT {request.path} ===\n{tb}\n\n")
            except Exception as write_err:
                print(f"Error logging middleware failed to write: {write_err}")
            raise e
