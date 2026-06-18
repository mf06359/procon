import std;
using namespace std;
inline void assert(bool cond) { if (!cond) std::abort(); }

const long long inf = 1e18;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);
    int n;
    cin >> n;
    int q;
    cin >> q;
    vector<int> box(n), pos(n), rev(n);
    for (int i = 0; i < n; i++) {
        box[i] = i;
        pos[i] = i;
        rev[i] = i;
    }
    for (;q--;) {
        int op, a, b;
        cin >> op;
        if (op == 1) {
            cin >> a >> b;
            a--;b--;
            box[a] = b;
        } else if (op == 2){
            cin >> a >> b;
            a--;b--;
            swap(pos[a], pos[b]);
        } else {
            cin >> a;
            a--;
            cout << 1 + pos[box[a]] << endl;
        }
    }
}

