extern int __VERIFIER_nondet_int();
extern void __VERIFIER_error();

int id(int x) {
  if (x==0) return 0;
  int ret = id2(x-1) + 1;
  if (ret > 2) return 2;
  return ret;
}

int id2(int x) {
  if (x==0) return 0;
  int ret = id(x-1) + 1;
  if (ret > 2) return 2;
  return ret;
}

void main() {
  int input = __VERIFIER_nondet_int();
  int result = id(input);
  if (result == 3) {
    __VERIFIER_error();
  }
}
