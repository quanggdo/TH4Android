# TH4 Mini E-Commerce (Core Logic)

Tài liệu này tóm tắt phần core logic để nhóm dựng UI cho bài TH4.
Project hiện tại đang theo hướng lưu dữ liệu local (SharedPreferences),
không phụ thuộc Firebase.

## 1. Mục tiêu và phạm vi

- Quản lý giỏ hàng liên màn hình bằng Provider.
- Lưu giỏ hàng offline, tắt/mở app vẫn giữ dữ liệu.
- Tạo đơn hàng từ các item được chọn và lưu lịch sử đơn hàng local.
- Sẵn sàng để lắp UI cho 4 màn hình: Home, Product Detail, Cart, Checkout/Orders.

## 2. Cấu trúc file core hiện tại

### Models

- lib/models/product.dart
	- Entity sản phẩm từ FakeStore API.
	- Field chính: id, title, price, description, category, image.
	- fromJson/toJson cho network và local.

- lib/models/cart_item.dart
	- Một dòng trong giỏ hàng.
	- Gồm full Product + quantity + isSelected + size + color.
	- toDTO() để chuyển sang payload gọn cho checkout.

- lib/models/cart_item_dto.dart
	- Payload gọn cho checkout/order request.
	- Field: productId, quantity, size, color, price.

- lib/models/order_request.dart
	- Input để tạo đơn hàng.
	- Gồm items (List<CartItemDTO>) + paymentMethod + shippingAddress + totalAmount + note.

- lib/models/order.dart
	- Bản ghi đơn hàng đã tạo.
	- Bổ sung metadata: id, status, createdAt.
	- fromRequest(), fromJson(), copyWith(status), toJson().

### Provider

- lib/providers/cart_provider.dart
	- Nguồn dữ liệu chính của giỏ hàng trong RAM.
	- Đồng bộ local sau mỗi thay đổi.
	- Expose các getter tính toán cho UI.

### Services

- lib/services/api_service.dart
	- Gọi FakeStore API bằng query parameters.
	- fetchProducts(limit, sort), fetchProductsByCategory(...), fetchCategories().
	- fetchProductsPage(page, pageSize, sort, category) để giả lập pagination.

- lib/services/storage_service.dart
	- saveCart/loadCart/clearCart bằng SharedPreferences.

- lib/services/order_service.dart
	- placeOrder(OrderRequest) -> tạo Order và lưu local.
	- loadOrderModels(), loadOrdersByStatus(status), getOrderById(id).
	- updateOrderStatus(id, status), cancelOrder(id), clearOrders().

### Utils

- lib/utils/app_constants.dart
	- baseApiUrl, key local storage, constants trạng thái đơn hàng.

- lib/utils/currency_utils.dart
	- Format tiền tệ để dùng chung toàn app.

## 3. Luồng dữ liệu tổng thể

1. Home
- UI gọi ApiService.fetchProducts(...) hoặc fetchProductsPage(...).
- Parse về List<Product>.

2. Product Detail
- Khi user bấm "Thêm vào giỏ": gọi CartProvider.addItem(product, size, color).
- Provider cập nhật _items -> save local -> notifyListeners().

3. Cart
- UI đọc CartProvider.items.
- Checkbox item: toggleSelect/toggleSelectAt.
- Checkbox "Chọn tất cả": toggleAll.
- Quantity +/-: incrementQuantity, decrementOrRemove.
- Tổng tiền realtime: đọc getter totalAmount (chỉ tính item đã tick).

4. Checkout
- buildSelectedOrderRequest(...) từ CartProvider.
- OrderService.placeOrder(orderRequest) để lưu đơn local.
- CartProvider.checkoutSelected() để xóa các item đã mua khỏi giỏ.

5. Orders
- loadOrderModels()/loadOrdersByStatus(status) để hiển thị tab
	pending/shipping/delivered/cancelled.

## 4. Các getter/method quan trọng cho UI Cart

- totalAmount
	- Tổng thanh toán chỉ của item đã check.

- isAllSelected
	- true khi 100% item đang được chọn.

- hasPartialSelection
	- true khi có chọn một phần (phục vụ tri-state checkbox).

- totalSelectedQuantity
	- Tổng số lượng của các item đã chọn (badge/tóm tắt).

- shouldConfirmRemoveOnDecrement(index)
	- Nếu quantity <= 1 thì UI hiện dialog "Bạn có muốn xóa không?".

- decrementOrRemove(index, confirmedRemove: ...)
	- quantity > 1 -> giảm bình thường.
	- quantity == 1 và confirmedRemove = true -> xóa item.

## 5. Cách nối Provider/Service vào UI

### main.dart

- Khai báo ChangeNotifierProvider<CartProvider> một lần ở root.
- CartProvider tự load local khi khởi tạo.

### Home Screen

- FutureBuilder + ApiService.fetchProductsPage(page: ..., pageSize: ...).
- Pull to refresh: reset page = 1, fetch lại.
- Infinite scroll: đến cuối danh sách -> page++ -> fetchProductsPage.

### Product Detail Screen

- Chọn size, color, quantity trong bottom sheet.
- Bấm xác nhận: context.read<CartProvider>().addItem(...).
- Hiện SnackBar thành công.

### Cart Screen

- Consumer<CartProvider> để lắng nghe thay đổi realtime.
- Tiếp nhận thao tác checkbox, +/-, dismiss delete.
- Sticky bottom bar đọc totalAmount.

### Checkout + Orders Screen

- Checkout:
	- Tạo request qua buildSelectedOrderRequest(...).
	- Gọi placeOrder(...), thông báo thành công.
	- Gọi checkoutSelected() để xóa item đã mua.

- Orders:
	- DefaultTabController 4 tab status.
	- Mỗi tab gọi loadOrdersByStatus(status).

## 6. Quy ước status đơn hàng

Status được chuẩn hóa ở app_constants:

- pending
- shipping
- delivered
- cancelled

Khuyến nghị UI map label:

- Chờ xác nhận -> pending
- Đang giao -> shipping
- Đã giao -> delivered
- Đã hủy -> cancelled

## 7. Checklist trước khi bắt đầu dựng UI đầy đủ

- [x] Core models/services/providers đã thống nhất.
- [x] Giỏ hàng lưu local và khôi phục dữ liệu on startup.
- [x] Đơn hàng local có lọc theo status và cập nhật status.
- [x] Unit tests đang pass.

## 8. Yêu cầu hiển thị TH4

Theo đề bài, AppBar trang chủ cần đặt đúng cú pháp:

- TH4 - Nhóm [Số nhóm]

Ví dụ: TH4 - Nhóm 03
