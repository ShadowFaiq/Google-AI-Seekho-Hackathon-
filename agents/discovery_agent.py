from database.mock_firestore import db

def discover_providers(service_category: str):
    """
    Filters providers from the database based on the service category.
    Returns a list of eligible providers.
    """
    providers = db.get_providers_by_category(service_category)
    return providers
