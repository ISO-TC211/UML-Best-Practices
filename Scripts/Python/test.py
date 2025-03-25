import re

# Sample string
text = "Some text before Theme=old_value; some text after"
print(text)
# Regular expression pattern to match the part starting with "Theme=" and ending with ";"
pattern = r"(Theme=)[^;]*(;)"

# Replacement string
replacement = r"\1ISO/TC 211\2"

# Perform the replacement
new_text = re.sub(pattern, replacement, text)

print(new_text)