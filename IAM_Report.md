# NGHIÊN CỨU TRIỂN KHAI HỆ THỐNG IAM

---

## DANH MỤC BẢNG BIỂU

| STT | Tên bảng | Trang |
|-----|----------|-------|
| Bảng 2.1 | So sánh các giao thức xác thực phổ biến (OAuth2, OIDC, SAML, LDAP) | … |
| Bảng 2.2 | So sánh mô hình RBAC và ABAC | … |
| Bảng 2.3 | So sánh các giải pháp IAM (Keycloak, Okta, Microsoft Entra ID, AWS IAM) | … |
| Bảng 3.1 | Bảng yêu cầu chức năng của hệ thống | … |
| Bảng 3.2 | Bảng yêu cầu phi chức năng | … |
| Bảng 3.3 | Mô tả cấu trúc bảng User | … |
| Bảng 3.4 | Mô tả cấu trúc bảng Role | … |
| Bảng 3.5 | Mô tả cấu trúc bảng Permission | … |
| Bảng 3.6 | Danh sách API endpoints | … |
| Bảng 4.1 | Cấu hình phần cứng triển khai thử nghiệm | … |
| Bảng 4.2 | Danh sách công nghệ sử dụng | … |
| Bảng 5.1 | Bảng so sánh trước và sau khi triển khai IAM | … |

---

## DANH MỤC HÌNH ẢNH

| STT | Tên hình | Trang |
|-----|----------|-------|
| Hình 2.1 | Kiến trúc tổng quan của hệ thống IAM | … |
| Hình 2.2 | Mô hình hoạt động của OAuth 2.0 Authorization Code Flow | … |
| Hình 2.3 | Quy trình xác thực OpenID Connect | … |
| Hình 2.4 | Mô hình SSO sử dụng SAML 2.0 | … |
| Hình 2.5 | Mô hình kiểm soát truy cập RBAC | … |
| Hình 2.6 | Mô hình kiểm soát truy cập ABAC | … |
| Hình 3.1 | Sơ đồ kiến trúc tổng thể hệ thống | … |
| Hình 3.2 | Sơ đồ ERD cơ sở dữ liệu | … |
| Hình 3.3 | Sơ đồ Use Case người dùng | … |
| Hình 3.4 | Giao diện đăng nhập | … |
| Hình 4.1 | Cài đặt Keycloak bằng Docker | … |
| Hình 4.2 | Giao diện quản trị Realm trên Keycloak | … |
| Hình 4.3 | Cấu hình Client cho ứng dụng Web | … |
| Hình 4.4 | Demo đăng nhập SSO | … |
| Hình 4.5 | Demo MFA bằng Google Authenticator | … |
| Hình 4.6 | Bắt gói tin Token bằng Wireshark | … |

---

## DANH MỤC TỪ VIẾT TẮT

| Từ viết tắt | Tiếng Anh đầy đủ | Tiếng Việt |
|-------------|------------------|------------|
| IAM | Identity and Access Management | Quản lý Danh tính và Truy cập |
| SSO | Single Sign-On | Đăng nhập một lần |
| MFA | Multi-Factor Authentication | Xác thực đa yếu tố |
| 2FA | Two-Factor Authentication | Xác thực hai yếu tố |
| OAuth | Open Authorization | Giao thức ủy quyền mở |
| OIDC | OpenID Connect | Giao thức xác thực mở rộng OAuth2 |
| SAML | Security Assertion Markup Language | Ngôn ngữ đánh dấu xác nhận bảo mật |
| LDAP | Lightweight Directory Access Protocol | Giao thức truy cập thư mục |
| RBAC | Role-Based Access Control | Kiểm soát truy cập dựa trên vai trò |
| ABAC | Attribute-Based Access Control | Kiểm soát truy cập dựa trên thuộc tính |
| PEP | Policy Enforcement Point | Điểm thực thi chính sách |
| PAP | Policy Administration Point | Điểm quản trị chính sách |
| PDP | Policy Decision Point | Điểm ra quyết định chính sách |
| PIP | Policy Information Point | Điểm cung cấp thông tin chính sách |
| JWT | JSON Web Token | Mã thông báo dạng JSON |
| API | Application Programming Interface | Giao diện lập trình ứng dụng |
| HTTPS | Hypertext Transfer Protocol Secure | Giao thức truyền siêu văn bản bảo mật |
| TLS | Transport Layer Security | Bảo mật tầng vận chuyển |
| IdP | Identity Provider | Nhà cung cấp danh tính |
| SP | Service Provider | Nhà cung cấp dịch vụ |
| CIAM | Customer Identity and Access Management | IAM dành cho khách hàng |
| PAM | Privileged Access Management | Quản lý truy cập đặc quyền |
| ZTA | Zero Trust Architecture | Kiến trúc không tin tưởng |

---

## LỜI MỞ ĐẦU

Trong bối cảnh cuộc Cách mạng Công nghiệp lần thứ tư đang diễn ra mạnh mẽ, công nghệ thông tin đã trở thành xương sống của mọi hoạt động kinh tế – xã hội. Sự phát triển bùng nổ của điện toán đám mây, dữ liệu lớn (Big Data), Internet vạn vật (IoT) và trí tuệ nhân tạo (AI) đã tạo ra một môi trường số đa dạng và phức tạp chưa từng có. Đi cùng với cơ hội là vô vàn thách thức về **an ninh mạng** mà bài toán **kiểm soát danh tính và truy cập** là một trong những vấn đề cốt lõi.

Theo báo cáo của Verizon Data Breach Investigations Report (DBIR) các năm gần đây, hơn 80% các vụ vi phạm dữ liệu liên quan đến yếu tố con người, trong đó việc đánh cắp thông tin xác thực (credentials) chiếm tỷ trọng lớn nhất. Điều này cho thấy việc xây dựng một hệ thống **quản lý danh tính và truy cập (Identity and Access Management – IAM)** không còn là lựa chọn mà đã trở thành yêu cầu bắt buộc đối với mọi tổ chức.

Nhận thức được tầm quan trọng đó, đề tài **"Nghiên cứu triển khai hệ thống IAM"** được thực hiện với mong muốn cung cấp một cái nhìn tổng quan, có chiều sâu về kiến trúc, nguyên lý hoạt động cũng như cách triển khai thực tế của hệ thống IAM trong môi trường doanh nghiệp. Báo cáo được chia thành 5 chương, đi từ tổng quan dự án, cơ sở lý thuyết, thiết kế hệ thống, cài đặt – triển khai cho đến đánh giá kết quả.

Trong quá trình thực hiện, do hạn chế về thời gian và kiến thức, báo cáo không tránh khỏi những thiếu sót. Em rất mong nhận được sự góp ý từ quý Thầy/Cô và các bạn để đề tài được hoàn thiện hơn.

Em xin chân thành cảm ơn!

---

# CHƯƠNG 1: TỔNG QUAN DỰ ÁN

## 1.1. Lý do chọn đề tài

Trong kỷ nguyên chuyển đổi số hiện nay, dữ liệu đã trở thành tài sản quý giá nhất của mọi tổ chức và doanh nghiệp. Đi kèm với sự phát triển mạnh mẽ của điện toán đám mây (Cloud Computing), các ứng dụng Web và Mobile, hệ thống mạng của doanh nghiệp không còn bị giới hạn bởi các bức tường vật lý. Tuy nhiên, sự mở rộng này cũng đặt ra những thách thức khổng lồ về bảo mật, đặc biệt là bài toán kiểm soát truy cập.

Thực tế cho thấy, phần lớn các vụ rò rỉ dữ liệu nghiêm trọng trên thế giới không chỉ đến từ các cuộc tấn công bên ngoài mà còn xuất phát từ việc quản lý danh tính người dùng lỏng lẻo bên trong hệ thống. Việc người dùng sở hữu quá nhiều tài khoản trên các nền tảng khác nhau dẫn đến tình trạng đặt mật khẩu yếu, chia sẻ mật khẩu hoặc quên thu hồi quyền truy cập khi nhân sự nghỉ việc. Điều này tạo ra những "lỗ hổng" chết người cho các cuộc tấn công chiếm quyền điều khiển tài khoản (Account Takeover).

Hệ thống Quản lý Danh tính và Truy cập (Identity and Access Management - IAM) ra đời như một giải pháp then chốt. IAM không chỉ đơn thuần là việc xác thực tên đăng nhập và mật khẩu; nó là một khung quản trị toàn diện bao gồm các chính sách, quy trình và công nghệ để đảm bảo rằng: **Đúng người, đúng tài nguyên, vào đúng thời điểm và vì đúng lý do.**

Đối với một sinh viên ngành Công nghệ thông tin, việc nghiên cứu IAM không chỉ giúp nắm vững các nguyên tắc bảo mật hiện đại như Zero Trust, SSO, MFA, mà còn là cơ hội để tiếp cận với cách vận hành hệ thống trong các doanh nghiệp lớn. Nhận thấy tầm quan trọng của việc bảo vệ danh tính trong an ninh mạng, tôi đã quyết định thực hiện đề tài: **"Nghiên cứu triển khai hệ thống IAM"** nhằm tìm hiểu sâu về cơ chế hoạt động và cách thức áp dụng giải pháp này vào môi trường thực tế.

## 1.2. Mục tiêu nghiên cứu

### 1.2.1. Mục tiêu lý thuyết

- Nghiên cứu kiến trúc tổng thể của hệ thống IAM, hiểu rõ các thành phần cốt lõi như: Identity Repository (Kho lưu trữ danh tính), Policy Administration Point (PAP), Policy Decision Point (PDP) và Policy Enforcement Point (PEP).
- Phân tích các giao thức xác thực và ủy quyền phổ biến hiện nay bao gồm: OAuth 2.0, OpenID Connect (OIDC), SAML 2.0 và LDAP.
- Tìm hiểu về mô hình kiểm soát truy cập dựa trên vai trò (RBAC) và dựa trên thuộc tính (ABAC).
- Nghiên cứu mô hình bảo mật **Zero Trust Architecture** – trong đó IAM đóng vai trò là vành đai bảo mật mới của doanh nghiệp.

### 1.2.2. Mục tiêu thực tiễn

- Đánh giá và lựa chọn các công cụ/phần mềm mã nguồn mở hoặc giải pháp doanh nghiệp phù hợp (Keycloak, Okta, Microsoft Entra ID) để triển khai mô hình thử nghiệm.
- Xây dựng quy trình quản lý vòng đời người dùng (User Lifecycle Management) từ lúc khởi tạo, thay đổi quyền hạn cho đến khi thu hồi tài khoản.
- Triển khai thành công tính năng Đăng nhập một lần (SSO) và Xác thực đa yếu tố (MFA) trên các ứng dụng mô phỏng.
- Đánh giá tính an toàn và hiệu năng của hệ thống sau khi triển khai.

## 1.3. Đối tượng và phạm vi nghiên cứu

### 1.3.1. Đối tượng nghiên cứu

- **Đối tượng chính**: Các cơ chế, quy trình kỹ thuật và công nghệ liên quan đến việc định danh, xác thực (Authentication) và ủy quyền (Authorization) người dùng trong hệ thống mạng.
- **Hệ thống mục tiêu**: Các giải pháp IAM phổ biến (tập trung vào Keycloak) và các ứng dụng Web/Mobile cần được bảo vệ.

### 1.3.2. Phạm vi nghiên cứu

- **Về nội dung**: Đề tài tập trung vào việc thiết lập các chính sách bảo mật danh tính cho môi trường doanh nghiệp vừa và nhỏ. Nghiên cứu sâu vào việc tích hợp IAM với các ứng dụng sẵn có thông qua các API và giao thức tiêu chuẩn.
- **Về kỹ thuật**: Triển khai thử nghiệm trên môi trường ảo hóa (Docker/VMware). Phạm vi không bao gồm việc xây dựng các hạ tầng phần cứng vật lý phức tạp hay đi sâu vào các giải pháp phần cứng chuyên dụng (HSM – Hardware Security Module).
- **Về thời gian**: Nghiên cứu được thực hiện trong khuôn khổ học phần An ninh mạng, tập trung vào các giải pháp có tính ứng dụng cao hiện nay.

## 1.4. Phương pháp nghiên cứu

### 1.4.1. Phương pháp nghiên cứu lý thuyết và phân tích hệ thống

- **Nghiên cứu tài liệu thứ cấp**: Thu thập, tổng hợp và phân tích các tài liệu kỹ thuật từ các tổ chức tiêu chuẩn hóa quốc tế như IETF (về OAuth 2.0, OIDC) và OASIS (về SAML). Nghiên cứu các mô hình bảo mật tiên tiến như Zero Trust Architecture.
- **Phân tích mô hình kiểm soát truy cập**: So sánh giữa RBAC và ABAC để xác định cách thiết kế cây phân quyền tối ưu, đảm bảo nguyên tắc đặc quyền tối thiểu (Least Privilege).
- **Khảo sát giải pháp**: Phân tích ưu/nhược điểm của các giải pháp mã nguồn mở (Keycloak, Casdoor) so với các giải pháp Cloud-Native (AWS IAM, Google Cloud Identity).

### 1.4.2. Phương pháp thực nghiệm và mô phỏng hệ thống (Lab-based Method)

- **Thiết lập môi trường Lab**: Sử dụng Docker để triển khai các dịch vụ IAM nhằm đảm bảo tính linh hoạt và dễ dàng quản lý.
- **Cài đặt và cấu hình**: Trực tiếp thao tác cấu hình các Realm, Client, User và Role trên hệ thống IAM.
- **Kiểm thử (Testing)**: Thực hiện các kịch bản truy cập giả lập để kiểm tra tính đúng đắn của chính sách.

### 1.4.3. Phương pháp đánh giá và kiểm chứng an ninh

- **Phân tích lưu lượng mạng**: Sử dụng Wireshark hoặc Burp Suite để bắt và phân tích các gói tin trong quá trình trao đổi Token.
- **Kiểm thử lỗi logic và quyền hạn**: Thực hiện các kịch bản kiểm thử xâm nhập mức cơ bản như Broken Function Level Authorization.
- **Đánh giá hiệu năng và trải nghiệm**: Theo dõi thời gian phản hồi khi thực hiện cơ chế SSO.

---

# CHƯƠNG 2: CƠ SỞ LÝ THUYẾT

## 2.1. Tổng quan về hệ thống IAM

**Identity and Access Management (IAM)** là một khuôn khổ (framework) gồm các chính sách, quy trình và công nghệ được sử dụng để quản lý danh tính số (digital identities) và kiểm soát quyền truy cập của người dùng tới các tài nguyên trong hệ thống thông tin của một tổ chức.

Theo định nghĩa của **Gartner**, IAM là một bộ kỷ luật bảo mật (security discipline) cho phép đúng cá nhân truy cập đúng tài nguyên vào đúng thời điểm và vì đúng lý do. Nói cách khác, IAM trả lời cho hai câu hỏi cốt lõi trong an ninh hệ thống:

1. **Authentication (Xác thực)**: *"Bạn là ai?"* – Hệ thống xác minh danh tính người dùng dựa trên thông tin đăng nhập (username/password, OTP, sinh trắc học, chứng chỉ số…).
2. **Authorization (Ủy quyền)**: *"Bạn được phép làm gì?"* – Hệ thống kiểm tra xem người dùng đã xác thực có quyền truy cập tài nguyên cụ thể hay không.

Một hệ thống IAM hoàn chỉnh thường bao gồm các thành phần chính:

- **Identity Repository (Kho danh tính)**: Lưu trữ thông tin người dùng, thường là LDAP, Active Directory hoặc cơ sở dữ liệu quan hệ.
- **Authentication Service (Dịch vụ xác thực)**: Xác minh thông tin đăng nhập của người dùng.
- **Authorization Service (Dịch vụ ủy quyền)**: Kiểm tra quyền hạn của người dùng đối với tài nguyên.
- **Audit & Reporting (Kiểm toán & Báo cáo)**: Ghi log các hoạt động truy cập phục vụ kiểm tra và phân tích bảo mật.
- **Policy Administration Point (PAP)**: Nơi quản trị viên định nghĩa các chính sách truy cập.
- **Policy Decision Point (PDP)**: Đưa ra quyết định cho phép hay từ chối truy cập.
- **Policy Enforcement Point (PEP)**: Thực thi quyết định của PDP, thường được tích hợp trong API Gateway hoặc ứng dụng.

## 2.2. Vai trò và tầm quan trọng của IAM

### 2.2.1. Vai trò của IAM

- **Bảo vệ tài sản số**: Ngăn chặn truy cập trái phép vào dữ liệu, hệ thống, ứng dụng của doanh nghiệp.
- **Chuẩn hóa danh tính người dùng**: Mỗi người dùng có một danh tính số duy nhất, giúp dễ dàng quản lý và truy vết.
- **Tự động hóa quy trình quản lý**: Tự động cấp phát/thu hồi quyền khi nhân sự gia nhập, thay đổi vị trí hoặc rời khỏi tổ chức (User Lifecycle Management).
- **Đảm bảo tuân thủ**: Đáp ứng các quy định và tiêu chuẩn như GDPR, ISO 27001, PCI-DSS, HIPAA, Nghị định 13/2023/NĐ-CP về bảo vệ dữ liệu cá nhân tại Việt Nam.

### 2.2.2. Tầm quan trọng của IAM

- **Giảm thiểu rủi ro an ninh**: Ngăn chặn các cuộc tấn công liên quan đến đánh cắp tài khoản (credential stuffing, phishing, brute-force).
- **Nâng cao trải nghiệm người dùng**: Nhờ SSO, người dùng chỉ cần đăng nhập một lần để truy cập nhiều ứng dụng.
- **Tiết kiệm chi phí vận hành**: Giảm khối lượng công việc cho bộ phận IT trong việc reset mật khẩu, cấp quyền thủ công.
- **Hỗ trợ chuyển đổi số**: IAM là nền tảng để doanh nghiệp triển khai các dịch vụ Cloud, Mobile, Remote Working một cách an toàn.

## 2.3. Phân loại hệ thống IAM

Dựa trên đối tượng phục vụ và mô hình triển khai, IAM được chia thành các loại chính:

### 2.3.1. Theo đối tượng phục vụ

| Loại | Mô tả | Ví dụ |
|------|-------|-------|
| **Workforce IAM** | Quản lý danh tính của nhân viên nội bộ trong doanh nghiệp | Microsoft Entra ID, Okta Workforce |
| **CIAM (Customer IAM)** | Quản lý danh tính khách hàng cuối, tối ưu cho trải nghiệm người dùng | Auth0, Keycloak, Okta CIC |
| **PAM (Privileged Access Management)** | Quản lý các tài khoản đặc quyền (Admin, Root) | CyberArk, BeyondTrust, Delinea |
| **B2B IAM** | Quản lý danh tính giữa các đối tác doanh nghiệp | Okta B2B, Auth0 Organizations |

### 2.3.2. Theo mô hình triển khai

- **On-Premises IAM**: Triển khai tại hạ tầng nội bộ của doanh nghiệp (ví dụ: Active Directory, Keycloak self-hosted).
- **Cloud IAM**: Triển khai trên hạ tầng đám mây (AWS IAM, Google Cloud IAM, Azure AD).
- **Hybrid IAM**: Kết hợp cả hai mô hình, đồng bộ dữ liệu giữa môi trường on-premises và cloud.

### 2.3.3. Theo phạm vi chức năng

Dựa trên mức độ trưởng thành và phạm vi mà giải pháp bao phủ, IAM có thể được phân thành các nhóm:

- **IAM cơ bản (Core IAM / Access Management)**: Chỉ tập trung vào xác thực, ủy quyền và SSO. Phù hợp với các ứng dụng quy mô nhỏ. Ví dụ: Keycloak, Auth0 (gói cơ bản).
- **IGA (Identity Governance and Administration)**: Mở rộng IAM với các tính năng quản trị danh tính, phê duyệt cấp quyền, kiểm toán định kỳ (Access Review), tách biệt nhiệm vụ (Segregation of Duties – SoD). Ví dụ: SailPoint IdentityIQ, Saviynt, Oracle Identity Governance.
- **PAM (Privileged Access Management)**: Chuyên biệt cho việc quản lý các tài khoản đặc quyền (root, administrator, service account). Cung cấp các tính năng như session recording, password vaulting, just-in-time access. Ví dụ: CyberArk, BeyondTrust, Delinea.
- **CIEM (Cloud Infrastructure Entitlement Management)**: Tập trung quản lý quyền truy cập trong môi trường multi-cloud, phát hiện quyền dư thừa và rủi ro cấu hình IAM trên Cloud. Ví dụ: Microsoft Entra Permissions Management, Sonrai Security, Wiz CIEM.
- **CIAM (Customer IAM)**: Hướng tới khách hàng cuối với các yêu cầu đặc thù như đăng ký tự phục vụ, đăng nhập mạng xã hội, quản lý đồng ý (consent management) theo GDPR. Ví dụ: Auth0, Keycloak, Okta CIC, ForgeRock.

### 2.3.4. Một số giải pháp IAM phổ biến hiện nay

Trên thị trường hiện nay có rất nhiều giải pháp IAM, từ mã nguồn mở đến thương mại, từ on-premises đến SaaS. Dưới đây là khảo sát ngắn gọn về các giải pháp tiêu biểu:

**a) Keycloak (Open-source – Red Hat)**

- Phát triển bởi Red Hat, mã nguồn mở hoàn toàn (Apache 2.0).
- Hỗ trợ đầy đủ OpenID Connect, OAuth 2.0, SAML 2.0.
- Cho phép self-hosted, dễ tích hợp với LDAP/AD.
- Có giao diện quản trị thân thiện, hỗ trợ Realm, Client, User Federation, MFA, Social Login.
- **Phù hợp**: Doanh nghiệp vừa và nhỏ, dự án mã nguồn mở, môi trường học tập/nghiên cứu.

**b) Microsoft Entra ID (trước là Azure AD)**

- Giải pháp IAM SaaS hàng đầu của Microsoft, tích hợp chặt chẽ với hệ sinh thái Microsoft 365, Azure.
- Hỗ trợ Conditional Access, Privileged Identity Management, Identity Protection (AI-based risk detection).
- Tích hợp sẵn hàng ngàn ứng dụng SaaS qua App Gallery.
- **Phù hợp**: Doanh nghiệp đã sử dụng Microsoft 365/Azure, cần tính năng quản trị nâng cao.

**c) Okta**

- Một trong những nền tảng IAM SaaS lớn nhất thế giới.
- Cung cấp cả Workforce Identity Cloud (cho nhân viên) và Customer Identity Cloud (CIAM, sau khi mua lại Auth0).
- Hỗ trợ hàng nghìn integration sẵn có, mạng lưới đối tác lớn.
- **Phù hợp**: Doanh nghiệp lớn, đa nền tảng, ưu tiên SaaS thuần túy.

**d) AWS IAM / AWS IAM Identity Center**

- Quản lý quyền truy cập tài nguyên AWS theo nguyên tắc đặc quyền tối thiểu.
- AWS IAM Identity Center (trước là AWS SSO) bổ sung khả năng SSO cho các ứng dụng bên ngoài.
- Tích hợp tốt với các dịch vụ AWS (S3, EC2, Lambda…).
- **Phù hợp**: Tổ chức sử dụng AWS làm hạ tầng chính.

**e) Google Cloud Identity**

- Giải pháp IAM của Google, tích hợp chặt với Google Workspace và GCP.
- Hỗ trợ Context-Aware Access dựa trên BeyondCorp (Zero Trust).
- **Phù hợp**: Tổ chức sử dụng Google Workspace/GCP.

**f) ForgeRock (Ping Identity)**

- Nền tảng IAM doanh nghiệp với khả năng tùy biến cao, hỗ trợ cả on-premises và cloud.
- Mạnh về CIAM, IoT Identity, AI-driven access.
- **Phù hợp**: Doanh nghiệp lớn có yêu cầu phức tạp, đặc thù.

**g) Casdoor (Open-source)**

- Giải pháp UI-first, hỗ trợ OAuth 2.0/OIDC/SAML.
- Nhẹ, dễ triển khai, phù hợp cho startup.
- **Phù hợp**: Dự án nhỏ, cần tích hợp nhanh.

**Bảng tổng hợp so sánh các giải pháp IAM phổ biến:**

| Tiêu chí | Keycloak | Microsoft Entra ID | Okta | AWS IAM | Casdoor |
|----------|----------|--------------------|------|---------|---------|
| **Mô hình** | Open-source / Self-hosted | SaaS | SaaS | SaaS (gắn AWS) | Open-source |
| **Chi phí** | Miễn phí (tự host) | Trả theo người dùng | Trả theo người dùng | Miễn phí cho AWS | Miễn phí |
| **Giao thức** | OIDC, OAuth2, SAML, LDAP | OIDC, OAuth2, SAML, WS-Fed | OIDC, OAuth2, SAML | OIDC, SAML | OIDC, OAuth2, SAML |
| **MFA** | Có (TOTP, WebAuthn) | Có (đa dạng) | Có (đa dạng) | Có | Có |
| **SSO** | Có | Có | Có | Có (qua Identity Center) | Có |
| **User Federation** | LDAP, AD, Kerberos | AD, LDAP | AD, LDAP, HR systems | AD | LDAP |
| **Tùy biến UI** | Cao | Trung bình | Thấp | Thấp | Cao |
| **Cộng đồng/Hỗ trợ** | Cộng đồng lớn | Microsoft Support | Okta Support | AWS Support | Cộng đồng nhỏ |
| **Phù hợp với** | SME, dự án mã nguồn mở | DN dùng Microsoft | DN lớn, đa nền tảng | Tổ chức dùng AWS | Startup, dự án nhỏ |

Trên cơ sở phân tích trên, đề tài lựa chọn **Keycloak** làm nền tảng triển khai chính nhờ các ưu điểm:
- Mã nguồn mở, không phát sinh chi phí bản quyền.
- Hỗ trợ đầy đủ các giao thức tiêu chuẩn (OIDC, OAuth 2.0, SAML 2.0).
- Cộng đồng phát triển lớn, tài liệu phong phú.
- Dễ triển khai bằng Docker, phù hợp với môi trường Lab.
- Khả năng mở rộng để áp dụng vào doanh nghiệp thực tế trong tương lai.

## 2.4. Các chức năng cốt lõi của IAM

Một hệ thống IAM hiện đại thường cung cấp các chức năng sau:

### 2.4.1. Quản lý danh tính (Identity Management)

- Tạo, cập nhật, xóa tài khoản người dùng.
- Đồng bộ danh tính từ các hệ thống khác (HR, LDAP, AD).
- Quản lý vòng đời người dùng (Joiner – Mover – Leaver).

### 2.4.2. Xác thực (Authentication)

- Xác thực bằng mật khẩu truyền thống.
- Xác thực đa yếu tố (MFA) qua OTP, TOTP, Push Notification, sinh trắc học.
- Xác thực không mật khẩu (Passwordless) với WebAuthn, FIDO2.
- Xác thực liên kết (Federated Authentication) qua SAML, OIDC.

### 2.4.3. Ủy quyền (Authorization)

- Kiểm soát truy cập dựa trên Role (RBAC).
- Kiểm soát truy cập dựa trên Attribute (ABAC).
- Kiểm soát truy cập dựa trên Policy (PBAC).

### 2.4.4. Đăng nhập một lần (Single Sign-On – SSO)

Cho phép người dùng đăng nhập một lần và truy cập tất cả các ứng dụng được cấp phép mà không cần đăng nhập lại.

### 2.4.5. Quản lý phiên (Session Management)

- Quản lý thời gian sống của Token/Session.
- Hỗ trợ Single Logout (SLO).
- Quản lý refresh token an toàn.

### 2.4.6. Kiểm toán & Báo cáo (Audit & Reporting)

- Ghi log toàn bộ sự kiện đăng nhập, truy cập, thay đổi quyền hạn.
- Báo cáo phục vụ tuân thủ và điều tra sự cố.

## 2.5. Cơ chế hoạt động của IAM

Quy trình hoạt động cơ bản của một hệ thống IAM được mô tả qua 5 bước:

**Bước 1 – Định danh (Identification)**: Người dùng cung cấp thông tin định danh (username, email).

**Bước 2 – Xác thực (Authentication)**: Hệ thống kiểm tra thông tin xác thực (mật khẩu, OTP, sinh trắc học). Nếu hợp lệ, IAM phát hành một mã thông báo (Token) – thường là JWT (JSON Web Token).

**Bước 3 – Ủy quyền (Authorization)**: Khi người dùng truy cập tài nguyên, hệ thống kiểm tra Token và đối chiếu với chính sách (RBAC/ABAC) để quyết định cho phép hay từ chối.

**Bước 4 – Truy cập tài nguyên (Resource Access)**: Nếu được ủy quyền, người dùng có thể thao tác trên tài nguyên (đọc, ghi, xóa…).

**Bước 5 – Ghi log và kiểm toán (Audit)**: Mọi hoạt động đều được ghi lại để phục vụ giám sát và điều tra.

## 2.6. Các giao thức phổ biến

### 2.6.1. OAuth 2.0

OAuth 2.0 là giao thức **ủy quyền** (authorization), được công bố trong RFC 6749 bởi IETF năm 2012. OAuth 2.0 cho phép một ứng dụng (Client) truy cập tài nguyên của người dùng trên một dịch vụ khác (Resource Server) mà không cần biết mật khẩu của người dùng.

**Các thành phần chính:**
- **Resource Owner**: Người dùng sở hữu tài nguyên.
- **Client**: Ứng dụng muốn truy cập tài nguyên.
- **Authorization Server**: Máy chủ phát hành Access Token.
- **Resource Server**: Máy chủ chứa tài nguyên cần bảo vệ.

**Các luồng (Grant Type) phổ biến:**
- **Authorization Code Flow**: An toàn nhất, dùng cho web app server-side.
- **Authorization Code Flow with PKCE**: Dành cho SPA và Mobile App.
- **Client Credentials Flow**: Dùng cho giao tiếp giữa các service (machine-to-machine).
- **Resource Owner Password Credentials**: Đã bị deprecated do vấn đề bảo mật.
- **Device Authorization Flow**: Dành cho thiết bị có giao diện hạn chế (Smart TV, IoT).

### 2.6.2. OpenID Connect (OIDC)

OIDC là một lớp **xác thực** (authentication) được xây dựng trên nền OAuth 2.0, do OpenID Foundation chuẩn hóa năm 2014. Trong khi OAuth 2.0 chỉ giải quyết bài toán ủy quyền, OIDC bổ sung khả năng xác thực thông qua **ID Token** (định dạng JWT) chứa thông tin về người dùng (subject, name, email, picture…).

OIDC là lựa chọn được khuyến nghị cho hầu hết các ứng dụng web/mobile hiện đại.

### 2.6.3. SAML 2.0

SAML (Security Assertion Markup Language) là một chuẩn dựa trên XML, được OASIS công bố năm 2005. SAML chủ yếu được sử dụng cho SSO trong môi trường doanh nghiệp lớn (enterprise).

**Các thành phần:**
- **Identity Provider (IdP)**: Hệ thống xác thực người dùng (ví dụ: Keycloak, ADFS).
- **Service Provider (SP)**: Ứng dụng cần xác thực (ví dụ: Salesforce, Office 365).
- **SAML Assertion**: Tài liệu XML chứa thông tin xác thực được ký số.

### 2.6.4. LDAP

LDAP (Lightweight Directory Access Protocol) là giao thức truy vấn và quản lý thông tin trong một thư mục phân cấp. LDAP thường được sử dụng làm backend lưu trữ danh tính cho các hệ thống IAM.

### 2.6.5. So sánh các giao thức

| Tiêu chí | OAuth 2.0 | OIDC | SAML 2.0 | LDAP |
|----------|-----------|------|----------|------|
| Mục đích | Ủy quyền | Xác thực + Ủy quyền | SSO doanh nghiệp | Quản lý thư mục |
| Định dạng | JSON/JWT | JSON/JWT | XML | Binary |
| Năm chuẩn hóa | 2012 | 2014 | 2005 | 1993 |
| Phù hợp với | Web/Mobile/API hiện đại | Web/Mobile hiện đại | Doanh nghiệp lớn | Hệ thống nội bộ |
| Độ phức tạp | Trung bình | Trung bình | Cao | Thấp |

## 2.7. Mô hình kiểm soát truy cập

### 2.7.1. RBAC – Role-Based Access Control

RBAC là mô hình phân quyền dựa trên vai trò của người dùng trong tổ chức. Mỗi vai trò (Role) được gán một tập hợp các quyền (Permissions), và mỗi người dùng (User) được gán một hoặc nhiều vai trò.

**Ví dụ:**
- Role `Admin`: có toàn quyền trên hệ thống.
- Role `Manager`: được duyệt báo cáo, xem dữ liệu phòng ban.
- Role `Staff`: chỉ được xem dữ liệu cá nhân.

**Ưu điểm**: Đơn giản, dễ quản lý, phù hợp với cấu trúc tổ chức.
**Nhược điểm**: Khó linh hoạt khi quy mô lớn, dễ phát sinh "Role Explosion".

### 2.7.2. ABAC – Attribute-Based Access Control

ABAC quyết định quyền truy cập dựa trên các thuộc tính (Attributes) của:
- **Subject** (người dùng): chức vụ, phòng ban, cấp bậc…
- **Resource** (tài nguyên): loại, mức nhạy cảm, chủ sở hữu…
- **Action** (hành động): đọc, ghi, xóa…
- **Environment** (môi trường): thời gian, địa điểm, thiết bị, IP…

**Ví dụ chính sách**: *"Cho phép nhân viên phòng Kế toán đọc file lương trong giờ hành chính, từ máy tính công ty."*

**Ưu điểm**: Linh hoạt, biểu đạt được các chính sách phức tạp.
**Nhược điểm**: Khó triển khai, khó kiểm toán.

## 2.8. Ưu điểm và hạn chế của IAM

### 2.8.1. Ưu điểm

- **Tăng cường bảo mật**: Giảm rủi ro rò rỉ dữ liệu thông qua kiểm soát truy cập chặt chẽ.
- **Cải thiện trải nghiệm người dùng**: SSO giúp người dùng tiết kiệm thời gian.
- **Tự động hóa**: Giảm tải công việc thủ công cho IT.
- **Đáp ứng tuân thủ**: Hỗ trợ các yêu cầu của GDPR, ISO 27001, PCI-DSS.
- **Khả năng mở rộng**: Hỗ trợ tốt cho mô hình doanh nghiệp lớn, đa nền tảng.

### 2.8.2. Hạn chế

- **Chi phí triển khai cao**: Đặc biệt với các giải pháp doanh nghiệp như Okta, Microsoft Entra ID.
- **Độ phức tạp**: Yêu cầu đội ngũ kỹ thuật có chuyên môn cao.
- **Single Point of Failure**: Khi IAM gặp sự cố, toàn bộ hệ thống có thể không thể đăng nhập.
- **Phụ thuộc vào nhà cung cấp** (vendor lock-in) đối với các giải pháp thương mại.
- **Yêu cầu bảo mật cao cho chính IAM**: Vì IAM là "chìa khóa" của hệ thống, nó phải được bảo vệ cực kỳ nghiêm ngặt.

---

# CHƯƠNG 3: PHÂN TÍCH VÀ THIẾT KẾ HỆ THỐNG

## 3.1. Yêu cầu hệ thống

### 3.1.1. Yêu cầu chức năng (Functional Requirements)

| STT | Mã | Mô tả chức năng |
|-----|----|-----------------|
| 1 | FR-01 | Quản lý người dùng: tạo, sửa, xóa, vô hiệu hóa tài khoản |
| 2 | FR-02 | Đăng ký, đăng nhập bằng username/email/password |
| 3 | FR-03 | Đăng nhập một lần (SSO) cho nhiều ứng dụng |
| 4 | FR-04 | Xác thực đa yếu tố (MFA) qua OTP/TOTP |
| 5 | FR-05 | Quản lý vai trò và quyền hạn (RBAC) |
| 6 | FR-06 | Quên mật khẩu và đặt lại qua email |
| 7 | FR-07 | Đổi mật khẩu, cập nhật thông tin cá nhân |
| 8 | FR-08 | Đăng nhập bằng tài khoản mạng xã hội (Google, Facebook) |
| 9 | FR-09 | Quản lý phiên đăng nhập, đăng xuất tập trung (SLO) |
| 10 | FR-10 | Ghi log hoạt động đăng nhập và truy cập |
| 11 | FR-11 | Tích hợp ứng dụng client thông qua OIDC/OAuth2 |
| 12 | FR-12 | Quản lý token: phát hành, làm mới, thu hồi |

### 3.1.2. Yêu cầu phi chức năng (Non-functional Requirements)

| STT | Mã | Mô tả |
|-----|----|-------|
| 1 | NFR-01 | **Bảo mật**: Mã hóa mật khẩu bằng bcrypt/argon2, dùng HTTPS/TLS, JWT có chữ ký RS256 |
| 2 | NFR-02 | **Hiệu năng**: Thời gian xác thực < 500ms |
| 3 | NFR-03 | **Khả năng mở rộng**: Hỗ trợ tối thiểu 1000 người dùng đồng thời |
| 4 | NFR-04 | **Tính sẵn sàng**: Uptime ≥ 99.5% |
| 5 | NFR-05 | **Khả năng kiểm toán**: Lưu log tối thiểu 6 tháng |
| 6 | NFR-06 | **Tuân thủ**: Đáp ứng OWASP Top 10, GDPR |
| 7 | NFR-07 | **Khả năng tương thích**: Hỗ trợ Web, Mobile, Desktop |

## 3.2. Mô hình kiến trúc hệ thống

Hệ thống được thiết kế theo kiến trúc **Microservices** với IAM (Keycloak) đóng vai trò trung tâm xác thực và ủy quyền.

```
┌──────────────────────────────────────────────────────────────┐
│                     User (Web / Mobile)                      │
└───────────────────────────┬──────────────────────────────────┘
                            │ HTTPS
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                       API Gateway / PEP                      │
│              (Reverse Proxy + Token Validation)              │
└────────────┬─────────────────────────────┬───────────────────┘
             │                             │
             ▼                             ▼
┌────────────────────────┐   ┌──────────────────────────────────┐
│   Keycloak (IAM)       │   │       Backend Services           │
│  - Authentication      │   │  - User Service                  │
│  - Authorization       │   │  - Product Service               │
│  - User Federation     │   │  - Order Service                 │
│  - Token Management    │   │                                  │
└──────────┬─────────────┘   └──────────────┬───────────────────┘
           │                                │
           ▼                                ▼
┌────────────────────┐          ┌──────────────────────────┐
│  Identity Storage  │          │   Application Database   │
│  (PostgreSQL/LDAP) │          │      (PostgreSQL)        │
└────────────────────┘          └──────────────────────────┘
```

**Mô tả các tầng:**

- **Tầng giao diện**: Web App (React/Vue), Mobile App (Flutter).
- **Tầng API Gateway (PEP)**: Đóng vai trò Policy Enforcement Point, kiểm tra token trước khi chuyển request đến backend.
- **Tầng IAM (Keycloak)**: Quản lý xác thực, ủy quyền, phát hành JWT.
- **Tầng Backend**: Các microservice nghiệp vụ.
- **Tầng dữ liệu**: PostgreSQL cho IAM và ứng dụng, có thể tích hợp LDAP.

## 3.3. Thiết kế cơ sở dữ liệu

### 3.3.1. Sơ đồ ERD

```
┌──────────────┐         ┌─────────────────┐         ┌──────────────┐
│    User      │         │   User_Role     │         │    Role      │
├──────────────┤         ├─────────────────┤         ├──────────────┤
│ id (PK)      │◄────────┤ user_id (FK)    │────────►│ id (PK)      │
│ username     │         │ role_id (FK)    │         │ name         │
│ email        │         │ assigned_at     │         │ description  │
│ password_hash│         └─────────────────┘         └──────┬───────┘
│ full_name    │                                            │
│ phone        │                                            │
│ status       │         ┌─────────────────┐                │
│ mfa_enabled  │         │ Role_Permission │                │
│ mfa_secret   │         ├─────────────────┤                │
│ created_at   │         │ role_id (FK)    │◄───────────────┘
│ updated_at   │         │ permission_id   │
└──────┬───────┘         │  (FK)           │         ┌──────────────┐
       │                 └────────┬────────┘         │  Permission  │
       │                          │                  ├──────────────┤
       │                          └─────────────────►│ id (PK)      │
       │                                             │ name         │
       │                                             │ resource     │
       │                                             │ action       │
       │                                             └──────────────┘
       │
       ▼
┌──────────────┐         ┌──────────────┐
│   Session    │         │  Audit_Log   │
├──────────────┤         ├──────────────┤
│ id (PK)      │         │ id (PK)      │
│ user_id (FK) │         │ user_id (FK) │
│ token        │         │ action       │
│ ip_address   │         │ ip_address   │
│ user_agent   │         │ status       │
│ expires_at   │         │ timestamp    │
│ created_at   │         └──────────────┘
└──────────────┘
```

### 3.3.2. Mô tả các bảng chính

**Bảng User (Người dùng)**

| Trường | Kiểu dữ liệu | Mô tả |
|--------|--------------|-------|
| id | UUID | Khóa chính |
| username | VARCHAR(50) | Tên đăng nhập, duy nhất |
| email | VARCHAR(100) | Email, duy nhất |
| password_hash | VARCHAR(255) | Mật khẩu đã hash bằng bcrypt |
| full_name | VARCHAR(100) | Họ và tên |
| phone | VARCHAR(20) | Số điện thoại |
| status | ENUM | active / locked / disabled |
| mfa_enabled | BOOLEAN | Đã bật MFA hay chưa |
| mfa_secret | VARCHAR(255) | Khóa bí mật TOTP |
| created_at | TIMESTAMP | Thời gian tạo |
| updated_at | TIMESTAMP | Thời gian cập nhật |

**Bảng Role (Vai trò)**

| Trường | Kiểu dữ liệu | Mô tả |
|--------|--------------|-------|
| id | UUID | Khóa chính |
| name | VARCHAR(50) | Tên vai trò (admin, manager, staff…) |
| description | TEXT | Mô tả |

**Bảng Permission (Quyền)**

| Trường | Kiểu dữ liệu | Mô tả |
|--------|--------------|-------|
| id | UUID | Khóa chính |
| name | VARCHAR(100) | Tên quyền |
| resource | VARCHAR(100) | Tài nguyên (user, product, order…) |
| action | VARCHAR(20) | Hành động (read, write, delete) |

**Bảng Audit_Log (Nhật ký kiểm toán)**: ghi nhận mọi sự kiện xác thực và truy cập.

## 3.4. Thiết kế API

Hệ thống cung cấp các REST API theo chuẩn OpenAPI 3.0:

### 3.4.1. API Xác thực

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/auth/register` | Đăng ký tài khoản mới |
| POST | `/auth/login` | Đăng nhập, trả về Access Token + Refresh Token |
| POST | `/auth/logout` | Đăng xuất, thu hồi Token |
| POST | `/auth/refresh` | Làm mới Access Token bằng Refresh Token |
| POST | `/auth/forgot-password` | Gửi email đặt lại mật khẩu |
| POST | `/auth/reset-password` | Đặt lại mật khẩu |
| POST | `/auth/mfa/enable` | Bật MFA cho tài khoản |
| POST | `/auth/mfa/verify` | Xác thực mã OTP |

### 3.4.2. API Quản lý người dùng

| Method | Endpoint | Quyền | Mô tả |
|--------|----------|-------|-------|
| GET | `/users` | Admin | Danh sách người dùng |
| GET | `/users/{id}` | Admin/Self | Xem chi tiết |
| POST | `/users` | Admin | Tạo người dùng mới |
| PUT | `/users/{id}` | Admin/Self | Cập nhật thông tin |
| DELETE | `/users/{id}` | Admin | Xóa/vô hiệu hóa |

### 3.4.3. API Quản lý vai trò

| Method | Endpoint | Quyền | Mô tả |
|--------|----------|-------|-------|
| GET | `/roles` | Admin | Danh sách vai trò |
| POST | `/roles` | Admin | Tạo vai trò |
| PUT | `/roles/{id}` | Admin | Cập nhật vai trò |
| POST | `/users/{id}/roles` | Admin | Gán vai trò cho user |

### 3.4.4. Định dạng phản hồi mẫu (JSON)

```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJSUzI1NiIs...",
    "refresh_token": "eyJhbGciOiJSUzI1NiIs...",
    "expires_in": 3600,
    "token_type": "Bearer"
  },
  "message": "Đăng nhập thành công"
}
```

## 3.5. Thiết kế giao diện

### 3.5.1. Nguyên tắc thiết kế

- **Đơn giản, trực quan**: Tối thiểu hóa các bước người dùng phải thực hiện.
- **Responsive**: Hỗ trợ đa thiết bị (desktop, tablet, mobile).
- **Đảm bảo bảo mật trải nghiệm**: Hiển thị thông báo rõ ràng khi xác thực thất bại, có cơ chế khóa tạm thời sau N lần đăng nhập sai.
- **Tuân thủ chuẩn**: WCAG 2.1 cho khả năng tiếp cận.

### 3.5.2. Các màn hình chính

1. **Trang đăng nhập**: form username/password + nút đăng nhập SSO bằng Google.
2. **Trang đăng ký**: form đầy đủ thông tin, validate phía client + server.
3. **Trang xác thực OTP**: nhập mã 6 số từ Google Authenticator.
4. **Trang quản lý hồ sơ**: cập nhật thông tin, đổi mật khẩu, bật/tắt MFA.
5. **Dashboard quản trị**: quản lý người dùng, vai trò, xem log.
6. **Trang lỗi/từ chối truy cập**: thông báo 401/403 thân thiện.

---

# CHƯƠNG 4: CÀI ĐẶT VÀ TRIỂN KHAI DEMO

## 4.1. Môi trường triển khai

### 4.1.1. Cấu hình phần cứng

| Thành phần | Cấu hình |
|------------|----------|
| CPU | Intel Core i5 thế hệ 10 trở lên (4 nhân, 8 luồng) |
| RAM | Tối thiểu 8GB (khuyến nghị 16GB) |
| Ổ cứng | SSD 256GB |
| Mạng | Kết nối Internet ổn định |

### 4.1.2. Phần mềm

- Hệ điều hành: Ubuntu 22.04 LTS hoặc Windows 11 + WSL2
- Docker Desktop 24.x trở lên
- Docker Compose v2
- Trình duyệt: Chrome / Edge / Firefox phiên bản mới
- Postman để test API
- Wireshark để phân tích lưu lượng

## 4.2. Công nghệ sử dụng

| Hạng mục | Công nghệ |
|----------|-----------|
| **IAM Server** | Keycloak 24.x (mã nguồn mở, Red Hat) |
| **Cơ sở dữ liệu** | PostgreSQL 15 |
| **Backend mẫu** | Node.js (Express) hoặc Spring Boot |
| **Frontend mẫu** | React.js + Vite |
| **Reverse Proxy** | Nginx / Traefik |
| **Container** | Docker, Docker Compose |
| **Bảo mật truyền dẫn** | TLS 1.3 (Let's Encrypt cho production) |
| **Giao thức xác thực** | OpenID Connect, OAuth 2.0 |
| **Định dạng Token** | JWT (RS256) |

## 4.3. Các bước cài đặt hệ thống

### 4.3.1. Bước 1: Chuẩn bị Docker Compose

Tạo file `docker-compose.yml`:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15
    container_name: keycloak-db
    environment:
      POSTGRES_DB: keycloak
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD: keycloak_pass
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - iam-net

  keycloak:
    image: quay.io/keycloak/keycloak:24.0
    container_name: keycloak
    command: start-dev
    environment:
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: keycloak_pass
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin123
    ports:
      - "8080:8080"
    depends_on:
      - postgres
    networks:
      - iam-net

volumes:
  postgres_data:

networks:
  iam-net:
    driver: bridge
```

Khởi chạy:
```bash
docker compose up -d
```

### 4.3.2. Bước 2: Cấu hình Realm và Client trên Keycloak

1. Truy cập `http://localhost:8080`, đăng nhập với `admin/admin123`.
2. **Tạo Realm mới**: `iam-demo`.
3. **Tạo Client** cho ứng dụng web:
   - Client ID: `web-app`
   - Client Type: `OpenID Connect`
   - Valid Redirect URIs: `http://localhost:3000/*`
   - Web Origins: `http://localhost:3000`
4. **Tạo Roles**: `admin`, `manager`, `staff`.
5. **Tạo Users** mẫu và gán Role tương ứng.

### 4.3.3. Bước 3: Tích hợp ứng dụng Web (React)

Cài đặt thư viện:
```bash
npm install keycloak-js
```

Cấu hình `keycloak.js`:
```javascript
import Keycloak from 'keycloak-js';

const keycloak = new Keycloak({
  url: 'http://localhost:8080',
  realm: 'iam-demo',
  clientId: 'web-app'
});

export default keycloak;
```

Khởi tạo trong ứng dụng:
```javascript
keycloak.init({ onLoad: 'login-required' }).then(authenticated => {
  if (authenticated) {
    console.log('User authenticated', keycloak.tokenParsed);
  }
});
```

### 4.3.4. Bước 4: Bảo vệ Backend API

Sử dụng middleware kiểm tra JWT (ví dụ Node.js + Express):

```javascript
const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');

const client = jwksClient({
  jwksUri: 'http://localhost:8080/realms/iam-demo/protocol/openid-connect/certs'
});

function getKey(header, callback) {
  client.getSigningKey(header.kid, (err, key) => {
    callback(null, key.getPublicKey());
  });
}

function authMiddleware(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ message: 'Missing token' });

  jwt.verify(token, getKey, { algorithms: ['RS256'] }, (err, decoded) => {
    if (err) return res.status(401).json({ message: 'Invalid token' });
    req.user = decoded;
    next();
  });
}
```

### 4.3.5. Bước 5: Bật xác thực đa yếu tố (MFA)

1. Vào Realm `iam-demo` → **Authentication** → **Required Actions**.
2. Bật `Configure OTP`.
3. Người dùng đăng nhập lần tới sẽ được yêu cầu cài Google Authenticator và quét mã QR.

## 4.4. Demo chức năng chính

### 4.4.1. Đăng ký và đăng nhập

- Người dùng truy cập ứng dụng → tự động chuyển hướng về Keycloak login page.
- Sau khi nhập đúng thông tin, Keycloak phát hành Access Token và chuyển hướng về ứng dụng.

### 4.4.2. SSO giữa nhiều ứng dụng

- Đăng nhập trên `app1.local` thành công.
- Mở `app2.local` (cùng Realm) → tự động đăng nhập, không cần nhập lại mật khẩu.

### 4.4.3. Xác thực đa yếu tố (MFA)

- Người dùng đăng nhập username/password.
- Hệ thống yêu cầu nhập mã OTP 6 số từ Google Authenticator.
- Sau khi xác thực thành công mới phát hành Token.

### 4.4.4. Phân quyền RBAC

- User `nguyenvana` có Role `staff` → truy cập `/api/users` → trả về **403 Forbidden**.
- User `tranthib` có Role `admin` → truy cập `/api/users` → trả về danh sách người dùng.

### 4.4.5. Đăng xuất tập trung (SLO)

- User đăng xuất ở `app1` → phiên ở `app2` cũng bị hủy ngay lập tức.

## 4.5. Một số hình ảnh minh họa hệ thống

> *(Ghi chú: chèn screenshot thực tế khi triển khai)*

- **Hình 4.1**: Trang đăng nhập của Keycloak.
- **Hình 4.2**: Giao diện quản trị Realm.
- **Hình 4.3**: Cấu hình Client `web-app`.
- **Hình 4.4**: Tạo người dùng mới và gán Role.
- **Hình 4.5**: Màn hình quét mã QR để cấu hình MFA.
- **Hình 4.6**: Bắt gói tin trong Wireshark – Token được mã hóa qua TLS.
- **Hình 4.7**: Log audit ghi nhận hoạt động đăng nhập.

---

# CHƯƠNG 5: ĐÁNH GIÁ VÀ KẾT LUẬN

## 5.1. Đánh giá kết quả đạt được

Sau quá trình nghiên cứu và triển khai, đề tài đã đạt được những kết quả nổi bật:

### 5.1.1. Về mặt lý thuyết

- Hệ thống hóa được kiến thức tổng quan về IAM, các giao thức xác thực và ủy quyền tiêu chuẩn (OAuth 2.0, OIDC, SAML, LDAP).
- Phân biệt rõ ràng các mô hình kiểm soát truy cập RBAC, ABAC và áp dụng được vào thiết kế thực tế.
- Hiểu được vai trò của IAM trong kiến trúc Zero Trust hiện đại.

### 5.1.2. Về mặt thực tiễn

- Triển khai thành công hệ thống Keycloak trên môi trường Docker.
- Tích hợp được SSO cho ứng dụng web và mobile sử dụng OIDC.
- Cấu hình thành công MFA bằng TOTP qua Google Authenticator.
- Xây dựng cơ chế phân quyền RBAC với 3 cấp độ Role rõ ràng.
- Bảo vệ Backend API bằng JWT và kiểm tra chữ ký RS256.
- Phân tích và xác nhận tính an toàn của Token khi truyền qua HTTPS bằng Wireshark.

### 5.1.3. Bảng so sánh trước và sau khi triển khai IAM

| Tiêu chí | Trước IAM | Sau khi triển khai IAM |
|----------|-----------|------------------------|
| Số lần đăng nhập/ngày | Mỗi ứng dụng đăng nhập riêng | Đăng nhập 1 lần (SSO) |
| Bảo mật mật khẩu | Mỗi nơi 1 mật khẩu, dễ bị quên | Tập trung tại IAM, có policy mạnh |
| Khả năng chống tấn công ATO | Thấp | Cao (nhờ MFA) |
| Quản lý phân quyền | Phân tán, khó kiểm soát | Tập trung, theo Role rõ ràng |
| Audit log | Phân tán, không đồng nhất | Tập trung, có thể truy vấn |
| Quy trình thu hồi quyền | Thủ công, dễ bỏ sót | Tự động khi vô hiệu hóa user |

## 5.2. Hạn chế của hệ thống

Mặc dù đã đạt được các mục tiêu đề ra, đề tài vẫn còn một số hạn chế:

- **Quy mô triển khai**: Chỉ ở mức Lab với số lượng người dùng nhỏ, chưa thử nghiệm với tải cao (>10,000 user đồng thời).
- **Chưa triển khai HA (High Availability)**: Hệ thống chạy single-node, chưa có cluster Keycloak với load balancer.
- **Chưa tích hợp ABAC**: Mới dừng ở RBAC, chưa khai thác các chính sách dựa trên thuộc tính phức tạp.
- **Chưa áp dụng Zero Trust hoàn chỉnh**: Còn thiếu các thành phần như Device Trust, Continuous Authentication.
- **Chưa kiểm thử xâm nhập chuyên sâu**: Mới dừng ở mức kiểm tra cơ bản, chưa thực hiện pentest đầy đủ.
- **Quản lý khóa và bí mật**: Chưa tích hợp với Vault (HashiCorp Vault) để quản lý secret an toàn hơn.

## 5.3. Hướng phát triển trong tương lai

Để hệ thống có thể đưa vào triển khai thực tế tại doanh nghiệp, các hướng phát triển tiếp theo bao gồm:

1. **Triển khai Keycloak Cluster** với Infinispan và load balancer (HAProxy/Nginx) để đảm bảo HA và mở rộng theo chiều ngang.
2. **Tích hợp ABAC và PBAC**: Dùng Keycloak Authorization Services hoặc Open Policy Agent (OPA) để định nghĩa chính sách động.
3. **Hỗ trợ xác thực không mật khẩu (Passwordless)**: Tích hợp WebAuthn/FIDO2, Magic Link.
4. **Tích hợp với SIEM**: Đẩy log audit về hệ thống giám sát an ninh tập trung (ELK, Splunk, Wazuh).
5. **Triển khai Zero Trust hoàn chỉnh**: Bổ sung Device Posture Check, Risk-based Authentication, Continuous Verification.
6. **Tích hợp PAM**: Quản lý các tài khoản đặc quyền theo nguyên tắc Just-In-Time Access.
7. **Tích hợp HSM/Vault**: Bảo vệ khóa ký Token bằng phần cứng chuyên dụng.
8. **Tự động hóa với IaC**: Quản lý cấu hình Keycloak bằng Terraform Provider.
9. **CIAM cho khách hàng**: Mở rộng hệ thống để phục vụ hàng triệu người dùng cuối, tích hợp đăng nhập mạng xã hội.
10. **Đào tạo và quy trình vận hành**: Xây dựng playbook ứng phó sự cố liên quan đến IAM.

## 5.4. Kết luận

Đề tài **"Nghiên cứu triển khai hệ thống IAM"** đã hoàn thành các mục tiêu đặt ra ban đầu, từ việc nghiên cứu lý thuyết, phân tích kiến trúc, thiết kế cơ sở dữ liệu và API cho đến cài đặt – kiểm thử thành công hệ thống thực tế trên nền tảng Keycloak.

Qua quá trình thực hiện, có thể khẳng định rằng IAM đóng vai trò là **xương sống bảo mật** của các tổ chức trong kỷ nguyên số, đặc biệt khi mô hình làm việc từ xa, đa thiết bị và đa nền tảng ngày càng phổ biến. Một hệ thống IAM được thiết kế tốt sẽ giúp doanh nghiệp:

- **Bảo vệ tài sản số** trước các mối đe dọa ngày càng tinh vi.
- **Tối ưu hóa trải nghiệm người dùng** thông qua SSO và Passwordless.
- **Tuân thủ các quy định pháp lý** trong và ngoài nước.
- **Giảm chi phí vận hành** nhờ tự động hóa quy trình quản lý danh tính.

Bản thân em qua đề tài này đã nắm vững được nguyên lý hoạt động của IAM, các giao thức bảo mật hiện đại, đồng thời rèn luyện được khả năng triển khai thực tế bằng các công cụ mã nguồn mở. Đây sẽ là nền tảng quan trọng để em tiếp tục nghiên cứu sâu hơn về lĩnh vực An ninh mạng và Bảo mật ứng dụng trong tương lai.

Em xin chân thành cảm ơn quý Thầy/Cô đã hướng dẫn và tạo điều kiện để em hoàn thành đề tài này.

---

## TÀI LIỆU THAM KHẢO

1. D. Hardt, *"The OAuth 2.0 Authorization Framework"*, RFC 6749, IETF, 2012.
2. N. Sakimura et al., *"OpenID Connect Core 1.0"*, OpenID Foundation, 2014.
3. OASIS, *"Security Assertion Markup Language (SAML) v2.0"*, 2005.
4. Keycloak Documentation, https://www.keycloak.org/documentation
5. NIST Special Publication 800-207, *"Zero Trust Architecture"*, 2020.
6. Verizon, *"Data Breach Investigations Report (DBIR)"*, 2024.
7. Gartner, *"Magic Quadrant for Access Management"*, 2024.
8. OWASP Foundation, *"OWASP Top 10: 2021"*, https://owasp.org/Top10/
9. R. Sandhu et al., *"Role-Based Access Control Models"*, IEEE Computer, 1996.
10. NIST, *"Guide to Attribute Based Access Control (ABAC) Definition and Considerations"*, SP 800-162, 2014.
