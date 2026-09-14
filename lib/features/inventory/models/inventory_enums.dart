enum InventoryListFilter { all, lowStock, outOfStock }

enum StockDirection { increase, decrease }

extension InventoryListFilterLabel on InventoryListFilter {
  String get label {
    switch (this) {
      case InventoryListFilter.all:
        return 'All Inventory';
      case InventoryListFilter.lowStock:
        return 'Low Stock';
      case InventoryListFilter.outOfStock:
        return 'Out Of Stock';
    }
  }
}

extension StockDirectionLabel on StockDirection {
  String get label {
    switch (this) {
      case StockDirection.increase:
        return 'Increase';
      case StockDirection.decrease:
        return 'Decrease';
    }
  }
}
