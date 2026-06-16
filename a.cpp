#include <cassert>
import std;
using namespace std;
void solve() {
    int n;
    cin >> n;
    vector<int> a(2 * n);
    vector<int> s(n, 0);
    for (int i = 0; i < 2 * n; i++) {
        cin >> a[i];
        a[i]--;
        s[a[i]] += i;
    }
    int ans = 0;
    for (int i = 1; i < 2 * n; i++) {
        int ax = s[a[i]] - i;
        if (abs(ax - i) == 1) continue;
        int bx = s[a[i - 1]] - (i - 1);
        if (abs(bx - i + 1) == 1) continue;
        if (abs(bx - ax) == 1 && ax != i - 1 && bx != i) {
            ans += 1;
        }
    }
    assert((ans & 1) == 0); 
    cout << ans / 2 << endl;
}
int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);
    int tt;
    cin >> tt;
    while (tt--) {
        solve();
    }
}
