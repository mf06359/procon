import std;
using namespace std;
const long long inf = 2e18;
void solve();
int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);
    int tt = 1;
    cin >> tt;
    while (tt--) solve();
}
void solve(){
    int h, w;
    vector<string> s(h);
    for (int i = 0; i < h; i++) cin >> s[i];
    vector dp(h + 1, vector<int> (w + 1, 0));
    for (int i = 0; i < h; i++) {
        for (int j = 0; j < w; j++) {
            dp[i + 1][j + 1] += s[i] == '#';
        }
    }
    for (int i = 0; i < h + 1; i++) {
        for (int j = 0; j < w; j++) {
            dp[i][j + 1] += dp[i][j];
        }
    }
    for (int j = 0; j < w + 1; j++) {
        for (int i = 0; i < h; i++) {
            dp[i + 1][j] += dp[i][j];
        }
    }
    
};
