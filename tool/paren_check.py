p = r"lib/features/auth/login_register_page.dart"
with open(p, 'r', encoding='utf-8') as f:
    s = f.read()
print('(' , s.count('('))
print(')' , s.count(')'))
print('{' , s.count('{'))
print('}' , s.count('}'))
print('[' , s.count('['))
print(']' , s.count(']'))
