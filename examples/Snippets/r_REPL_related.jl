# --- snippets that are related to the use inside REPL:
# --- discussion: https://discourse.julialang.org/t/user-console-input-read-readline-input/15031/27

# *** ***************************************************************************************************************************
# --- Are we inside VScode-REPL or in a CLI/Terminal-Window:
isincli() = isempty(Base.PROGRAM_FILE)
if ~isincli()
    error("Please run this script inside a command line interface.")
end
str = Base.prompt("[Y] / N ? ") in ("","y","Y") ? "Y" : "N"
