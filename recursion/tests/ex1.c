int f(int x) {
  x = x + 2;
  return x;
}

int main() {
  int b;
  int a = 2;
  b =  a + f(3);
  return 0;
}
