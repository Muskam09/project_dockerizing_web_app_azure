from drf_spectacular.views import SpectacularSwaggerView
from rest_framework.permissions import AllowAny

class PublicSwaggerView(SpectacularSwaggerView):
    permission_classes = [AllowAny]