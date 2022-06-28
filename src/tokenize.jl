import Base: eltype, iterate, IteratorEltype, IteratorSize, show
using Base: HasEltype, SizeUnknown

struct Tokens
    a_string::String
end

IteratorSize(::Type{Tokens}) = SizeUnknown()
IteratorEltype(::Type{Tokens}) = HasEltype()
eltype(::Type{Tokens}) = Token{<: Any}

struct TokensState
    line_number::Int
    current_index::Int
    character::Char
    next_index::Int
    already_finished::Bool
end

struct Token{Content}
    token_type::Symbol
    content::Content
    line_number::Int
end

function iterate_character(tokens, tokens_state)
    next_index = tokens_state.next_index
    iteration = iterate(tokens.a_string, next_index)
    if iteration === nothing
        TokensState(
            tokens_state.line_number,
            tokens_state.current_index,
            tokens_state.character,
            next_index,
            true)
        )
    else
        current_index = next_index
        character, next_index = iteration
        TokensState(
            tokens_state.line_number,
            current_index,
            character,
            next_index,
            false)
        )
    end
end

function show(io::IO, token::Token)
    print(io, "Token(")
    show(io, token.token_type)
    content = token.content
    if content !== nothing
        print(io, ", ")
        show(io, token.content)
    end
    print(io, "; line_number = ")
    show(io, token.line_number)
    print(io, ")")
end

function chunk(belongs_function, tokens, tokens_state)
    next_tokens_state = iterate_character(tokens, tokens_state)
    if !(next_tokens_state.already_finished)
        while belongs_function(next_tokens_state.character) &&
            tokens_state = next_tokens_state
            next_tokens_state = iterate_character(tokens, tokens_state)
            if next_tokens_state.already_finished
                break
            end
        end
    end
    tokens_state, next_tokens_state
end

function parse_fraction(tokens, line_number, start_index, current_index, next_index)
    current_index, next_index = chunk(tokens, current_index, next_index) do character
        isdigit(character)
    end
    Token(:float, parse(Float64, SubString(tokens.a_string, start_index:current_index)), line_number),
    TokensState(line_number, next_index)
end

function parse_number(tokens, line_number, start_index, current_index, next_index)
    a_string = tokens.a_string

    current_index, next_index = chunk(tokens, current_index, next_index) do character
        isdigit(character)
    end
    iteration = iterate(a_string, next_index)
    if iteration === nothing
        Token(:integer, parse(Int, SubString(a_string, start_index:current_index)), line_number),
        TokensState(line_number, next_index)
    else
        next_character, next_next_index = iteration
        if next_character == '.'
            current_index = next_index
            character, next_index = next_character, next_next_index
            iteration = iterate(a_string, next_index)
            if iteration === nothing
                Token(:float, parse(Float64, SubString(a_string, start_index:current_index)), line_number),
                TokensState(line_number, next_index)
            else
                next_character, next_next_index = iteration
                if isdigit(next_character)
                    current_index = next_index
                    character, next_index = next_character, next_next_index
                    parse_fraction(tokens, line_number, start_index, current_index, next_index)
                else
                    Token(:float, parse(Float64, SubString(a_string, start_index:current_index)), line_number),
                    TokensState(line_number, next_index)
                end
            end
        else
            Token(:integer, parse(Int, SubString(a_string, start_index:current_index)), line_number),
            TokensState(line_number, next_index)
        end
    end
end

function iterate(tokens)
    current_index = 1
    iteration = iterate(tokens.a_string, current_index)
    if iteration === nothing
        nothing
    else
        character, next_index = iteration
        iterate(tokens, TokensState(1, current_index, character, next_index, false))
    end
end

function iterate(tokens, tokens_state)
    a_string = tokens.a_string
    if tokens_state.already_finished
        nothing
    else
        current_index = tokens_state.current_index
        character = tokens_state.character
        next_index = tokens_state.next_index
        start_index = current_index
        line_number = tokens_state.line_number
        if character == '\n'
            current_index, next_index = chunk(tokens, current_index, next_index) do character
                character == '\n'
            end
            line_number = line_number + next_index - start_index
            Token(:newlines, nothing, line_number),
            TokensState(line_number, next_index)
        elseif character == ' '
            current_index, next_index = chunk(tokens, current_index, next_index) do character
                character == ' '
            end
            iterate(tokens, TokensState(line_number, next_index))
        elseif character == '#'
            current_index, next_index = chunk(tokens, current_index, next_index) do character
                character != '\n'
            end
            Token(:lyrics, SubString(a_string, start_index:current_index), line_number),
            TokensState(line_number, next_index)
        elseif isdigit(character)
            parse_number(tokens, line_number, start_index, current_index, next_index)
        elseif character == '.'
            iteration = iterate(a_string, next_index)
            if iteration === nothing
                throw(ErrorException("Unexpected . on line $line_number"))
            else
                next_character, next_next_index = iteration
                if isdigit(next_character)
                    current_index = next_index
                    character, next_index = next_character, next_next_index
                    parse_fraction(tokens, line_number, start_index, current_index, next_index)
                else
                    throw(ErrorException("Unexpected . on line $line_number"))
                end
            end
        elseif character == '-'
            iteration = iterate(a_string, next_index)
            if iteration === nothing
                throw(ErrorException("Unexpected - on line $line_number"))
            else
                next_character, next_next_index = iteration
                if next_character == '.' || isdigit(next_character)
                    current_index = next_index
                    character, next_index = next_character, next_next_index
                    parse_number(tokens, line_number, start_index, current_index, next_index)
                else
                    throw(ErrorException("Unexpected - on line $line_number"))
                end
            end
        elseif character == ':'
            Token(:colon, nothing, line_number),
            TokensState(line_number, next_index)
        elseif character == '/'
            Token(:slash, nothing, line_number),
            TokensState(line_number, next_index)
        elseif character == ','
            Token(:comma, nothing, line_number),
            TokensState(line_number, next_index)
        else
            current_index, next_index = chunk(tokens, current_index, next_index) do character
                # digits can be at the middle or end, but not the start, of symbols
                character != '\n' &&
                character != ' ' &&
                character != '#' &&
                character != '.' &&
                character != '-' &&
                character != ':' &&
                character != '/' &&
                character != '/'
            end
            Token(:symbol, Symbol(SubString(a_string, start_index:current_index)), line_number),
            TokensState(line_number, next_index)
        end
    end
end


show(collect(Tokens(read("examples/simple.justly", String))))
x = Tokens(read("examples/simple.justly", String))
first(x)
iterate(x)
iterate(x, iterate(x)[2])

s = "∀ x ∃ y"