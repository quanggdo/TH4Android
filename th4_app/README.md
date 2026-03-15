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
	- Field chính: id, title, price, description, category, image, rating.
	- rating là object riêng (ProductRating) gồm rate và count.
	- fromJson/toJson cho network và local.

- lib/models/cart_item.dart
	- Một dòng trong giỏ hàng.
	- Gồm full Product + quantity + isSelected + size + color.
	- toDTO() chuyển sang DTO có snapshot Product để lưu đơn hàng đầy đủ thông tin hiển thị.

- lib/models/cart_item_dto.dart
	- DTO item dùng cho checkout/order request.
	- Field: productId, product, quantity, size, color, unitPrice.
	- Có fromJson/toJson và tương thích ngược dữ liệu cũ còn key price.

- lib/models/order_request.dart
	- Input để tạo đơn hàng.
	- Gồm items (List<CartItemDTO>) + paymentMethod + shippingAddress + totalAmount + note.
	- Có fromJson/toJson để parse và lưu trữ nhất quán.

- lib/models/order.dart
	- Bản ghi đơn hàng đã tạo.
	- items được typed là List<CartItemDTO> (thay vì List<Map<String, dynamic>>).
	- Bổ sung metadata: id, status, createdAt.
	- fromRequest(), fromJson(), copyWith(status), toJson().

### Provider

- lib/providers/cart_provider.dart
	- Nguồn dữ liệu chính của giỏ hàng trong RAM.
	- Đồng bộ local sau mỗi thay đổi.
	- Expose các getter tính toán cho UI.
	- buildSelectedOrderRequest() tính totalAmount từ unitPrice * quantity của selected DTO để khóa chặt tính nhất quán payload.

### Services

- lib/services/api_service.dart
	- Gọi FakeStore API bằng query parameters.
	- fetchProducts(limit, sort), fetchProductsByCategory(...), fetchCategories().
	- fetchProductsPage(page, pageSize, sort, category) để giả lập pagination.

- lib/services/storage_service.dart
	- saveCart/loadCart/clearCart bằng SharedPreferences.

- lib/services/order_service.dart
	- placeOrder(OrderRequest) -> tạo Order và lưu local.
	- Validate dữ liệu trước khi lưu:
		- items không rỗng.
		- productId khớp product.id.
		- quantity >= 1.
		- unitPrice >= 0.
		- totalAmount phải khớp tổng các item (sai số cho phép 0.01).
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

Lưu ý dữ liệu:
- Mỗi item trong order đã chứa snapshot Product đầy đủ.
- UI Orders có thể hiển thị title/image/category/rating kể cả khi danh mục sản phẩm gốc thay đổi hoặc API tạm không trả dữ liệu.

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
- [x] Dữ liệu item order lưu đủ snapshot Product để hiển thị lại ổn định.
- [x] Validate tính nhất quán tổng tiền và item trước khi tạo đơn.
- [x] Unit tests đang pass.

## 8. Yêu cầu hiển thị TH4

Theo đề bài, AppBar trang chủ cần đặt đúng cú pháp:

- TH4 - Nhóm [Số nhóm]

Ví dụ: TH4 - Nhóm 03
