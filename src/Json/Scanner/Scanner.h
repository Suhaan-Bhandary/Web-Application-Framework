#ifndef INCLUDED_JSON_SCANNER
#define INCLUDED_JSON_SCANNER

#include <fstream>
#include <string>
#include <vector>

#include "../Token/Token.h"

namespace Json {
class Scanner {
   public:
    Scanner() = delete;
    Scanner(const char* source);
    
    Scanner(const Scanner& otherScanner);
    Scanner& operator=(const Scanner& otherScanner);

    Scanner(Scanner&& otherScanner);
    Scanner& operator=(Scanner&& otherScanner);

    // Public Functions to use in parser
    bool isAtEnd();
    Token advanceToken();
    Token peekToken();

   private:
    int start, current, line;
    const char* source;

    // Function returns one token at a time
    Token scanTokensOneByOne();

    // Functions
    Token scanToken();
    Token stringToken();
    Token numberToken(char firstChar);
    Token identifierToken();

    void trimCharacters();

    Token createToken(TokenType type);
    Token createToken(TokenType type, const std::string& literal);
    Token createToken(TokenType type, double literal);
    Token createToken(TokenType type, long long literal);

    char advance();
    bool match(char expected);
    char peek();

    bool isNextFourCharacterDigit();
    bool isHexCharacter(char ch);
    bool isNumberStart(char ch);
    bool isAlpha(char ch);
};
}  // namespace Json

#endif