# --- code dealing with regular expressions:

# ------------------------------------------------------------------------------------------
# https://www.pcre.org/current/doc/html/pcre2syntax.html
# https://perldoc.perl.org/perlre#Modifiers
# ------------------------------------------------------------------------------------------

using Printf

s_text = "This house has 4 DöÜrs. And the line continues!"
# -----------------------------------------------------------------------------------------
# \d:   decimal digit ||  \s: white space ||  \D: not a decimal digit  || .  any character except newline
# \V:   character that is not a vertical white space character (includes as well punctuation chars)
# [a-zA-Z] all a-Z Characters.
# [a-zA-ZäöüÄÖÜ] all a-Z Characters and also äöüÄÖÜ
# +     one or more, greedy, {n}    exactly n occurance
# ------------------------------------------------------------------------------------------

# *******************************************************************************************************************************
# --- Examples with two static regular expressions:

r_search_pattern    = r"(?<line_begin>\D+)(?<number_and_space>\d{1,3}\s)\s*?(?<word>[a-zA-ZäöüÄÖÜ]+)(?<EndOfLine>.+)"
r_search_pattern_b  = Regex("(?<line_begin>\\D+)(?<number_and_space>\\d{1,3}\\s)\\s*?(?<word>[a-zA-ZäöüÄÖÜ]+)(?<EndOfLine>.+)")
# --- results of static search:
match_result        = match(r_search_pattern, s_text)
match_result_b      = match(r_search_pattern_b, s_text)
@show match_result.match
@show match_result_b.match


# *******************************************************************************************************************************
# --- Dynamic regular expression:

# --- variables that may change during programm execution: ---
s_new_number = "5 "
s_new_word = "Windows"
# --- add these values into a dynamic search regular expression:
s_substitution = SubstitutionString("\\g<line_begin>" * s_new_number * s_new_word * "\\g<EndOfLine>")


# *******************************************************************************************************************************
# --- search result handling:
if match_result === nothing
    println("Regualr Expression not found")
else
    println(string("String found: ", match_result.match))
    println(match_result)
    result_string = replace(s_text, r_search_pattern => s_substitution, count = 1)
end

println("New text: ", result_string)

# --- second case:
s_text          = "LSQ_num_periods = 1   # 0 = take max full periods includet in sample of data \n"
s_text_b        = "println(\"LSQ_num_periods = \", 4)"
_variable_name  = "LSQ_num_periods"
_new_variable_value = 4
r_search_pattern = Regex("^" * _variable_name * "(?<equal_sign>\\s*?=\\s*?)(?<EndOfLine>.+)" )
# ---
if isa(_new_variable_value, Int)
    s_substitution   = @sprintf("%s = %i", _variable_name, _new_variable_value)
else
    s_substitution   = @sprintf("%s = %f", _variable_name, _new_variable_value)
end
# ---
match_result_b   = match(r_search_pattern, s_text)

if occursin(r_search_pattern, s_text)
    println(replace(s_text, r_search_pattern => s_substitution, count = 1))
else
    @info("Search pattern not found!")
end

# *******************************************************************************************************************************
# --- extract numbers from string:

str_ = "sda ++ -1.234f-4 ghs"
number_ = Parsers.parse(Float64, match(r"-?\d*\.?\d+(e[+-]?\d*)?", str_).match)

# --- in form of a function:
extract_number(_str) = Parsers.parse(Float64, match(r"-?\d*\.?\d+(e[+-]?\d*)?", _str).match)

# --- if also the notation XYZf-/+XY are possible you may use Meta.parse() instead of Parsers.parse()
str_ = "sda ++ -1.234f-5 ghs"
extract_number(_str) = Float64(Meta.parse(match(r"-?\d*\.?\d+([ef][+-]?\d*)?", _str).match))
number_ = extract_number(str_)
# --- source: https://discourse.julialang.org/t/extracting-a-float-from-a-string/43126/30


# *******************************************************************************************************************************
# --- ascertain the decimal delimiter:
begin
    nr1_ = "234.12"
    nr2_ = "123,45"
    r_comma_in_numbers = Regex("\\d+,\\d+")
    println("nr1_: ", occursin(r_comma_in_numbers, nr1_))
    println("nr2_: ", occursin(r_comma_in_numbers, nr2_))
end
