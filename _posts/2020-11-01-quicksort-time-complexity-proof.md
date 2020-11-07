---
layout: post
title: Chứng minh giải thuật QuickSort có độ phức tạp trung bình là O(NLogN)
tags: [algorithm, proof]
use_math : true
---

Bài viết sẽ chứng minh thuật toán QuickSort có độ phức tạp trung bình là **O(NLogN)**. Sau đây là đoạn mã thuật toán QuickSort trên nền ngôn ngữ Java.

```java
  public static int partition(int A[], int f, int l) {
    int pivot = A[f];
    while (f < l) {
      while (A[f] < pivot) f++;
      while (A[l] > pivot) l--;
      swap(A, f, l);
    }
    return f;
  }

  public static void Quicksort(int A[], int f, int l) {
    if (f >= l) return;
    int pivot_index = partition(A, f, l);
    Quicksort(A, f, pivot_index);
    Quicksort(A, pivot_index + 1, l);
  }
```

Đặt $A_n$ là một mảng gồm $N$ phần tử được phân bố ngẫu nhiên $a_1$, $a_2$, $a_3$, ..., $a_{n-1}$, $a_n$. Gọi $F_n$ là số lần so sánh trung bình khi thực hiện thuật toán QuickSort trên mảng $A_n$.

Sau khi kết thúc lần phân hoạch đầu tiên, $\exists$ vị trí $k$ chia mảng $A_n$ thành 2 phân hoạch thỏa mãn điều kiện $\forall i < k: a_i \leq a_k$ và  $\forall j > k: a_k < a_j$. Ví dụ như sau:

- \{$a_1$ $a_2$ ... $a_{k-1}$\}  $a_k$ \{$a_{k+1}$ ... $a_{n-1}$ $a_n$\}

Ta nhận thấy luôn cần cố định $N+1$ phép so sánh để tạo thành 2 phân hoạch như vậy. Tiếp tục sắp xếp trên 2 phân hoạch con đến khi phân hoạch con có kích thước là 1, mảng $A_n$ ban đầu sẽ được sắp xếp. Điều này luôn làm được vì sau mỗi lần phân hoạch, 2 phân hoạch con tạo ra luôn có kích thước bé hơn phân hoạch ban đầu.

Từ nhận xét trên, ta có công thức truy hồi tổng số lần so sánh tại vị trí có index là $k$:

- $F_n = (N+1) + F_{k-1} + F_{n-k}$

Do mảng được phân bố đều nên xác suất trung bình xảy tại vị trí thứ $k$ $\forall k=\overline{1,n}$ là $\frac{1}{N}$. Do vậy:

$ F_n = (N+1) + \frac{1}{N} \sum_{k=0}^{N-1}(F_{k-1} + F_{N-k}) (1) $

$ = (N+1) + \frac{1}{N}(\sum_{k=0}^{N-1}F_{k-1} + \sum_{k=0}^{N-1}F_{k-1})$

$ = (N+1) + \frac{2}{N}\sum_{k=0}^{N-1}F_{k-1} $ $($ Lí do: $\sum_{k=0}^{N-1}F_{k-1} = \sum_{k=0}^{N-1}F_{N-k}$ $)$

Nhân $N$ cho 2 vế, ta được:

- $N * F_N = N(N+1) + 2 * \sum_{k=0}^N F_{k-1} (2) $

Áp dụng $(2)$ với $N-1$, ta được:

- $(N-1) * F_{N-1} = (N-1)N + 2 * \sum_{k=0}^{N-1} F_{k-1} (3) $

Lấy $(2) - (3)$ vế theo vế, ta được:

$ N * F_N - (N-1)*F_{N-1} = 2 \* N + 2 * F_{N-1} $

$ \leftrightarrow N*F_N = 2 \* N + (N+1) \* F_{N-1} $    

Chia vế theo vế cho $N*(N+1)$ ta được:

$ \frac{F_N}{N+1} =  \frac{2}{N+1} + \frac{F_{N-1}}{N} $

$ = \frac{2}{N+1} + (\frac{2}{N} + \frac{F_{N-2}}{N-1}) $

$ = ... $

$ = \frac{2}{N+1} + \frac{2}{N} + ... + \frac{2}{3} + \frac{F_1}{2} $

Nhân vế theo vế cho $N+1$ ta được: 

$ F_N = 2 * (N+1) * (\frac{1}{2} + \frac{1}{3} + ... + \frac{1}{N} \frac{1}{N+1}) $

Nhận thấy chuỗi số $ \mathscr H_N = 1 + \frac{1}{2} + \frac{1}{3} + ... + \frac{1}{N} $
là "harmonic series" có giá trị $\simeq LogN$. Do vậy:

$ F_N = 2 * (N+1) * (1 + \frac{1}{2} + \frac{1}{3} + ... + \frac{1}{N}) - 2  \* (N+1) + 2 $

$ = 2 * (N+1) * \mathscr H_N - 2 * N  $

$ \simeq 2 * (N+1) * LogN - 2 * N  $

$ \simeq N * LogN  (6) $

Từ (6) ta thấy độ phức tạp trung bình của giải thuật QuickSort là $O(NLogN)$

