import std;
using namespace std;
inline void assert(bool cond) { if (!cond) std::abort(); }
const int inf = 1e9;
int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);
    int h, w;
    cin >> h >> w;
    vector<string> s(h);
    for (int i = 0; i < h; i++) {
        cin >> s[i];
    }
    int x[4] = {0, w - 1, 0, h - 1};
    for (int k = 0; k < 50; k++) {
        bool flag = true;
        if (x[0] >= x[1]) break;
        for (int i = 0; i < h; i++) {
            if (s[i][x[0]] == '#') flag = false;
        }
        if (flag) {
            for (int i = 0; i < h; i++) {
                s[i][x[0]] = ' ';
            }
            x[0]++;
        }
        if (x[0] >= x[1]) break;
        flag = true;
        for (int i = 0; i < h; i++) {
            if (s[i][x[1]] == '#') flag = false;
        }
        if (flag) {
            for (int i = 0; i < h; i++) {
                s[i][x[1]] = ' ';
            }
            x[1]++;
        }
        if (x[2] >= x[3]) break;
        flag = true;
        for (int i = 0; i < w; i++) {
            if (s[x[2]][i] == '#') flag = false;
        }
        if (flag) {
            for (int i = 0; i < w; i++) {
                s[x[2]][i] = ' ';
            }
            x[2]++;
        }
        if (x[0] >= x[1]) break;
        flag = true;
        for (int i = 0; i < w; i++) {
            if (s[x[3]][i] == '#') flag = false;
        }
        if (flag) {
            for (int i = 0; w < h; i++) {
                s[x[3]][i] = ' ';
            }
            x[3]++;
        }
    }
    for (int i = 0; i < h; i++) {
        int cnt = 0;
        for (char c: s[i]) {
            if (c != ' ') {
                cout << c;
                cnt++;
            }
        }
        if (cnt > 0) cout << "\n";
    }
}
