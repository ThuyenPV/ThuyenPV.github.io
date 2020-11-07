---
layout: post
title: Lịch sử phát triển giao thức HTTP 3.0 và ứng dụng trong gRPC
tags: [distributed system, networking]
---

Bài viết sẽ giới thiệu về lịch sử phát triển của giao thức HTTP, đặc biệt là HTTP/2 và ứng dụng của HTTP/2 trong giao thức gRPC.

**Giới thiệu: gRPC là gì**

gRPC là một giao thức mà giao thức mạng xây dựng trên nền HTTP/2 và message delivery format là Protobuf. Mỗi lựa chọn đều giúp cho GRPC có những ưu thế vượt trội hơn so với giao thức phổ biến khác là Restful.

Bài viết này sẽ nhấn mạnh về khía cạnh đầu tiên: ứng dụng của HTTP/2 trong gRPC.

Fun fact: "g" có nhiều nghĩa, nhưng nó không phải là "google". [g stands for](https://github.com/grpc/grpc/blob/master/doc/g_stands_for.md)

# Lịch sử phát triển giao thức HTTP 1.x

## HTTP 0.9

Khi lướt web, với giao diện đơn giản và dễ thương như [www.google.com](wwww.google.com) thì người dùng đã thực chất phải download rất nhiều thứ ở đằng sau.

Dựa vào hình vẽ này, chúng ta có thể đoán được đã có bao nhiêu request để tải được trang google ?

![](/assets/img/2020-05-30/google.png)

Hơn thế, các trang web bây giờ hoạt động chủ yếu qua giao thức HTTPS. Với mỗi HTTPS request sẽ có các bước:
- TCP 3-way handshake: vì HTTP/HTTPS được xây dựng trên giao thức TCP.
- TLS handshake: trao đổi thông tin khoá để encrypt data.
- Bắt đầu thực sự trao đổi dữ liệu.
- Đóng connection sau khi kết thúc.

--> Để có thể load được một trang đơn giản như [https://www.google.com](https://www.google.com), thì số round trip là cực kì khủng khiếp.

![](/assets/img/2020-05-30/tcp+tls.png)

Chúng ta có thể kiểm tra dễ dàng bằng cách dùng command line `tcpdump` và `wireshark` để kiểm tra quá trình này:

```bash
hqt@localhost:~$ sudo tcpdump port 443 -w output.pcap
hqt@localhost:~$ wireshark output.pcap
```

![](/assets/img/2020-05-30/wireshark-capture.png)

## HTTP 1.0

Việc lặp lại quá trình bắt tay cho mỗi request trong một phiên hoạt động là không cần thiết. Do vậy HTTP 1.1 cung cấp một flag `Keep-Alive`. Flag `Keep-Alive` cho phép việc tái sử dụng chung một TCP connection cho việc gửi nhận nhiều request/response trong một phiên hoạt động.

Ví dụ về [HTTP Pipeline](https://en.wikipedia.org/wiki/HTTP_pipelining)

![](/assets/img/2020-05-30/http-pipeline.png)

Tuy nhiên, các request vẫn phải gửi nhận tuần tự, không thể gửi nhận song song. Do khi đó, các packet giữa các request xen lẫn vào nhau, và không thể tách rõ ra được một TCP packet thuộc về request nào.

## HTTP 1.1

`Keep-Alive` flag trở thành giá trị mặc định.

### References
- [Explain keep-alive mechanism](https://stackoverflow.com/questions/20763999/explain-http-keep-alive-mechanism)
- [Wiki: keepalive](https://en.wikipedia.org/wiki/HTTP_persistent_connection)

# HTTP 2.0
Được phát triển bởi Google, giao thức có tên ban đầu là SPDY và được sử dụng cho cơ sở hàng tầng bên trong của Google. Sau đấy, SPDY được phát triển thành một giao thức mở và được hỗ trợ trên đa số các trình duyệt hiện tại.

Ngắn gọn thì HTTP/2 tốt hơn HTTP/1 trên nhiều phương diện. Đơn giản nhất là mình vào trang [http://www.http2demo.io](http://www.http2demo.io) sẽ có live demo việc download một bức ảnh kích thước lớn dùng HTTP/1 và HTTP/2.

Những điểm mới nào trong giao thức HTTP 2.0 ?

## 1. Multiplexing

Một bài toán đơn giản như sau: Viết phần mềm chat hỗ trợ 3 thao tác:
- Client connect đến server: server sẽ trả về cho client một ID định danh. Client đồng thời có thể lấy hết toàn bộ danh sách clients đã connect vào server.
- Client có thể gửi một tin nhắn cho một client khác.
- Client khi nhận được message từ một client khác: print ra màn hình tin nhắn nhận được.

**Định nghĩa:** cung cấp khả năng trình duyệt có thể gửi nhiều request trên cùng một connection và nhận lại response với thứ tự bất kì.

**Thử thách:** Một HTTP request bao gồm nhiều TCP packets, tương tự cho HTTP response. Và các packet này có thể xen lẫn nhau khi server nhận được, tương tự về phía client. Không mất tính tổng quát, giả sử mỗi HTTP request bao gồm 3 TCP packets. đấy, thứ tự nhận được của server khi client gửi 3 HTTP request R1 / R2 / R3 có thể là: [R1->P3; R2->P1; R3->P1; R2->P2; R3->P2; R1->P1; R2->P3; R1->P2; R3->P1]

**Giải quyết**
- Mỗi packet của cùng một request phải có thêm ID định danh ở header.
- Khi server nhận được packet đó, sẽ tự động sắp xếp vào từng slot hợp lí, đến khi nhận được thành công toàn bộ một request.
- Khi đấy, server sẽ xử lí request đấy và trả về response cho client.

**Ví dụ**
```
R1: [P1; P2]

R2: [P2; P3]

R3: [P1; P2; P3] --> sẵn sàng xử lí.
```

**Implementations** 
[Golang: hashicorp/yamux](https://github.com/hashicorp/yamux/blob/master/spec.md)

**So sánh giữa HTTP 1.1 và HTTP/2 (multiplexing)**

![](/assets/img/2020-05-30/http-1-2-comparision.png)

## 2. Stream concepts
- Frame: Đơn vị giao tiếp nhỏ nhất trong giao thức HTTP/2.
- Message: một chuỗi các frame liên tục nhau để tạo thành một HTTP request / HTTP response hợp lệ.
- Stream: một luồng giao tiếp 2 chiều giữa client và server. một stream có thể có nhiều message. Có thể hiểu đơn giản như một đoạn hội thoại giữa client và server.

Trong cùng một TCP connection, có thể có nhiều stream.

![](/assets/img/2020-05-30/http-stream.png)

## 3. Flow control
- Server có thể đang quá tải, không thể nhận thêm nhiều request được nữa.
- Có thể thực hiện bằng TCP flow control. Tuy nhiên, TCP flow control điều khiển ở layer thấp hơn, không đủ tốt trong nhiều tính huống, ví dụ như giữa các stream (trên cùng một tcp connection).

**Stream Priority**
![](/assets/img/2020-05-30/stream-priority.png)

- Hình 1: stream A sẽ chiếm 12/16 tài nguyên hiện có và stream B sẽ chiếm 4/16 tài nguyên hiện có.
- Hình 2: Hệ số ở stream D và stream C là không quan trọng.
- Hình 3: stream A chiếm 12/16 tài nguyên hiện có và stream B chiếm 4/16 tài nguyên hiện có. Tuy nhiên, stream C sẽ luôn được ưu tiên cao hơn.

**References**
- [Flow control](https://developers.google.com/web/fundamentals/performance/http2#flow_control)
- [Medium: HTTP/2 Flow control](https://medium.com/coderscorner/http-2-flow-control-77e54f7fd518)

## 4. Server push
Cho phép server trả về resources cho client trước khi client yêu cầu. Điều này tăng performance vì chúng ta không phải tốn time cho một request từ client -> server.

![](/assets/img/2020-05-30/server-push.png)

## 5. Header compression

HTTP 1.1, mỗi request đều được gửi kèm các header chuẩn, và cookies (nếu có), 500-800 bytes cho mỗi request. Đa phần các giá trị này lặp lại giữa các request.

**Giải pháp** Sử dụng định dạng nén `HPACK`. Cách tiếp cận có những điểm mới so với các thuật toán nén khác:
- Áp dụng thuật toán nén vào dữ liệu.
- Song song đó, cần có sự trợ giúp của client và server trong việc quy đĩnh sẵn một số giá trị, và cache sẵn các giá trị để tiết kiệm payload gửi trên đường truyền.

Bao gồm các cách tối ưu:
- Static dictionary: Server và client chia sẻ chung một list tĩnh mapping giữa key và value trong header, bao gồm 61 giá trị. Tham khảo ở [đây](https://http2.github.io/http2-spec/compression.html#static.table.definition)
```
1  :authority
2  :method  GET
3  :method  POST
4  :path  /
5  :path  /index.html
...
```

- Dynamic dictionary: server và client duy trì một dictionary của các field đã từng được sử dụng. Danh sách này có kích thước cố định, và sẽ xoá đi các phần tử cũ khi tới ngưỡng.
- Huffman Encoding: sử dụng một bản static Huffman để encode bất kì kí tự nào. Thực tế cho thấy Huffman encoding đã tiết kiệm 30% kích thước header.

Trong hình vẽ dưới đây, thuật toán nén HPACK đã tiết kiệm được hơn 50% kích thước.

![](/assets/img/2020-05-30/hpack-performance.png)

Một ví dụ khác về header compression.

![](/assets/img/2020-05-30/header-compression.png)

**References**
- [HPACK: The silence killer](https://blog.cloudflare.com/hpack-the-silent-killer-feature-of-http-2/)
- [Header compression](https://developers.google.com/web/fundamentals/performance/http2#header_compression)
- [Header compression spec](https://http2.github.io/http2-spec/compression.html)

### 6. Binary Framing
- Làm việc trên định dạng binary thay vì text.
- Có ngữ nghĩa tương thích với HTTP 1.1 (verb, header,...)

![](/assets/img/2020-05-30/binary-frame.png)

# HTTP 3.0
Google xây dựng một giao thức mới tên là [QUIC](https://www.wikiwand.com/en/QUIC).

## 1. Tăng tốc việc handshake
việc handshake bao gồm 2 bước: 3-way handshake và TLS handshake. Có thể tối ưu hoá lại việc này trong ít bước hơn:

![](/assets/img/2020-05-30/quick-handshake.png)

## 2. Xây dựng trên nền giao thức UDP

Một số lí do chuyển qua giao thức UDP:
- Giao thức TCP quản lí một số thứ như: TCP congression control, reliable control .... Tuy nhiên, việc thay đổi cách hoạt động của giao thức TCP rất khó. (phải thay đổi từ tầng hệ điều hành).
- Giải quyết bài toán "head-of-line blocking": Đó là khi một loạt các packets phải chờ cho packet đầu tiên. Giả sử ta có một buffer để chứa các packet có kích thước là 10. Buffer nhận được các packet từ 2->11, do buffer bị đầy nên không thể nhận thêm được nữa, buộc phải chờ packet 1.

Bài toán này được HTTP/2 giải quyết ở tầng HTTP layer: 2 HTTP request không cần phải chờ nữa, vì có thể đi song song trên đường truyền. Tuy nhiên, vấn đề vẫn còn ở tầng TCP. 

Ví dụ ta có 2 request HTTP: 
- request 1: packet từ 1 -> 5. 
- request 2: 6 -> 10 

TCP buffer có kích thước là 8. Nếu như hiện tại buffer là: [2,3,4,5,6,7,8,9]. TCP buộc phải chờ cho packet 1 đến trước khi có thể nhận thêm packet khác.

![](/assets/img/2020-05-30/http3-udp.png)

## 3. Encrypt transport header

Nhiều header vẫn có thể thấy được ở giao thức HTTP over TLS, có thể bị leak hoặc chỉnh sửa thông tin header.

![](/assets/img/2020-05-30/encrypted-transport-header.png)

## Tổng kết

![](/assets/img/2020-05-30/http-summary.png)

Load trang google trên trình duyệt chrome

![](/assets/img/2020-05-30/chrome-loading.png)

Load trang google trên trình duyệt firefox

![](/assets/img/2020-05-30/firefox-loading.png)

**References**
- [Head-of-line blocking](https://www.wikiwand.com/en/Head-of-line_blocking)
- [Modernize internet with HTTP/3](https://www.fastly.com/blog/modernizing-the-internet-with-http3-and-quic)

# GRPC functionalities based on HTTP2

## Stream

Có 4 kiểu function trong grpc:

- Unary call
- Client stream
- Server stream
- Bidirectional stream

```
service ViteTestService {
    rpc BothUnary (Request) returns (Response);
    rpc ClientStream (stream Request) returns (Response);
    rpc ServerStream (Request) returns (stream Response);
    rpc BothStream (stream Request) returns (stream Response);
}
```

Mỗi một lời gọi rpc sẽ được thực hiện trên một HTTP/2 stream.

## gRPC channel

**Channel:** là một "kết nối ảo" tới một endpoint trên server, nhưng ở đằng sau có thể là rất nhiều HTTP/2 connection khác được gRPC duy trì.

**Noted:** Connection pool vẫn chưa có trên Golang gRPC (hoặc có thể cả giao thức gRPC). Có một lần test thử, performance sẽ bị giảm khủng khiếp khi tạo ra 10,000 connection tới server. (giải thích: một lí do có thể là head-of-line blocking)
 
![](/assets/img/2020-05-30/grpc-channel.png)
 
## Others
- Client / server load balancing
- Connection managers: quản lí; kiểm tra; và duy trì các kết nối.
- Phát hiện các kết nối hỏng.
- Giữ các kết nối alive: thường xuyên gửi PING request. Song song với việc kiểm tra các kết - nối còn có thể giữ các kết nối trong tình trạng hoạt động.
- ...

**References**
- [Protocol HTTP/2 in gRPC](https://github.com/grpc/grpc/blob/master/doc/PROTOCOL-HTTP2.md)
- [gRPC metadata](https://github.com/grpc/grpc-go/blob/master/Documentation/grpc-metadata.md)
- [gRPC on HTTP/2: Engineering A Robust, High Performance Protocol](https://www.cncf.io/blog/2018/08/31/grpc-on-http-2-engineering-a-robust-high-performance-protocol/)
- [How are gRPC calls mapped to HTTP/2 streams](https://github.com/grpc/grpc-java/issues/3849)

# GRPC Ecosystem

## GRPC Gateway
![](/assets/img/2020-05-30/grpc-gateway.png)

Các bước thực hiện

- Update file protobuf với các metadata để service một HTTP endpoint.

```protobuf
syntax = "proto3";
 package example;

import "google/api/annotations.proto";

message StringMessage {
   string value = 1;
}

service YourService {
  rpc Echo(StringMessage) returns (StringMessage) {
    option (google.api.http) = {
      post: "/v1/example/echo"
      body: "*"
    };
  }
 }
```

- Generate protobuf file to stub file. (e.g.: service.pb.go).
- Import file vào grpc server.
- Import file vào reverse proxy.
- Client sẽ gửi HTTP request (e.g.: curl / wget / ...) vào con reverse proxy bằng giao thức RESTFUL.

## gRPC for Web

![](/assets/img/2020-05-30/grpc-web.png)

Các bước thực hiện
- Generate protobuf file cho phía server. (e.g: service.pb.go)
- Generate protobuf file cho phía client (e.g.: service.pb.js)
- Server import service mới (bằng code) và deploy lại.
- Client sẽ dùng file được sinh để gọi qua Envoy proxy. Từ đó envoy-proxy sẽ thay đổi request để tương thích với HTTP/2 / gRPC và gửi vào gRPC service.

**Câu hỏi** Tại sao lại cần envoy-proxy đứng ở giữa ?

**Trả lời** Không phải mọi API của HTTP/2 đều được expose bởi client. [Nguồn tham khảo](https://github.com/grpc/grpc-web/issues/347)

```
However, for gRPC-Web to work, we need a lot of the underlying transport to be exposed to us but that's not the case currently cross browsers. We cannot leverage the full http2 protocol given the current set of browser APIs.
```

## So sánh gRPC gateway và gRPC for Web

**grpc-gateway**
- Client/Frontend không cần quan tâm về giao thức gRPC.
- Cần phải sửa đổi server và reverse-proxy mỗi khi cập nhật file protobuf.
- Quản lí reverse-proxy như một service bình thường.

**grpc-web**
- Client/Frontend đóng vài trò như một gRPC-client, cần phải generate lại file phù hợp mỗi khi-  protobuf thay đổi.
- Envoy proxy không cần update khi mà file protobuf thay đổi.
Quản lí envoy proxy giống như quản lí nginx/ haproxy, thuần hơn về mặt devops.

## Reference
- [HTTP/3: the past, the present, and the future](https://blog.cloudflare.com/http3-the-past-present-and-future/)
- [Performance in HTTP/2](https://developers.google.com/web/fundamentals/performance/http2)