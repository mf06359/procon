import std;
using namespace std;
int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);
    int n, tt;
    cin >> n;
    lazy_segment_tree<S, op, e, F, mapping, composition, id> seg(n);
    for (;tt--;) {
        int l, r;
        cin >> l >> r;
        l--;
    }
}
