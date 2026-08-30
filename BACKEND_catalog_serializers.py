# ──────────────────────────────────────────────────────────────
# PASTE THIS INTO YOUR BACKEND: apps/catalog/serializers.py
# This adds low_price (min selling price across pharmacies)
# to the Medicine API response so the frontend can display prices.
# ──────────────────────────────────────────────────────────────

from django.db.models import Min
from rest_framework import serializers
from .models import Brand, Category, Medicine


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = "__all__"


class BrandSerializer(serializers.ModelSerializer):
    class Meta:
        model = Brand
        fields = "__all__"


class MedicineSerializer(serializers.ModelSerializer):
    category = CategorySerializer(read_only=True)
    brand = BrandSerializer(read_only=True)
    low_price = serializers.SerializerMethodField()

    class Meta:
        model = Medicine
        fields = "__all__"

    def get_low_price(self, obj):
        """Return the lowest selling price across all pharmacies."""
        result = obj.inventory_items.aggregate(
            min_price=Min("selling_price")
        )
        return result["min_price"] or 0
