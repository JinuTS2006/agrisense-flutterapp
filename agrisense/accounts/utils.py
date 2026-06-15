from rest_framework.views import exception_handler
import traceback

def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)

    tb = traceback.format_exc()
    try:
        import os
        log_path = "/tmp/django_error_log.txt"
        with open(log_path, "a", encoding="utf-8") as f:
            view_name = context.get('view').__class__.__name__ if context.get('view') else 'UnknownView'
            f.write(f"=== DRF EXCEPTION IN {view_name} ===\n")
            f.write(f"Exception: {str(exc)}\n")
            f.write(f"Traceback:\n{tb}\n\n")
    except Exception as e:
        print(f"Failed to write exception to log file: {e}")

    return response
