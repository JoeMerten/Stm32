//#include <string>

class MyClass {
public:
    explicit MyClass() {}
public:
    int publicMemberVar = 1;
protected:
    int protectedMemberVar = 2;
private:
    int privateMemberVar = 3;
};

int globaleVariableInt;
//std::string globaleVariableString;
MyClass globaleVariableMyClass;

namespace bla {
    int namespaceVariableInt;
    //std::string namespaceVariableString;
    MyClass namespaceVariableMyClass;
}

int main() {
    int lokaleVariableInt;
    //std::string lokaleVariableString;
    MyClass lokaleVariableMyClass;
    return 0;
}
