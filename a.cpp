import std;
using namespace std;
const long long inf = 2e18;
template <class T>
struct fenwick {
    int n;
    std::vector<T> bit; // 1-indexed

    fenwick(int n_) : n(n_), bit(n_ + 1, T{}) {}

    void add(int i, T x) {
        for (++i; i <= n; i += i & -i) bit[i] += x;
    }

    /// sum of a[0..i)
    T prefix(int i) const {
        T s = T{};
        for (; i > 0; i -= i & -i) s += bit[i];
        return s;
    }

    /// sum of a[l..r)
    T sum(int l, int r) const { return prefix(r) - prefix(l); }

    /// smallest index where prefix_sum >= x, assuming all elements are non-negative
    int lower_bound(T x) {
        int k = 1; while ((k << 1) <= n) k <<= 1;
        int i = 0;
        for (int len = k; len > 0; len >>= 1) {
            if (i + len <= n && bit[i + len] < x) {
                i += len;
                x -= bit[i];
            }
        }
        return i;
    }
};
void solve();
int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);
    int tt = 1;
    //cin >> tt;
    while (tt--) solve();
}
void solve(){
    int n, m;
    cin >> n >> m;
    vector<int> g(m);
    for (int i = 0; i < m; i++) {
        cin >> g[i];
        g[i]--;
    }
    fenwick<long long> f(n + 1);
    for (int i = 0; i < m; i++) {
        f.add(g[i], 1);
    }
    long long ans = 0;
    for (int i = 0; i < m; i++) {
        ans += f.sum(0, g[i]);
        f.add(g[i], -1);
    }
    cout << ans << endl;
};
