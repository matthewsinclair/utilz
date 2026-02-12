# Implementation - ST0004: xtrct - Semantic Data Extraction

## Implementation

To be filled in during implementation.

## Key Implementation Notes

### Anthropic SDK usage

```python
import anthropic

client = anthropic.Anthropic()  # uses ANTHROPIC_API_KEY env var
message = client.messages.create(
    model=model,
    max_tokens=4096,
    system=system_prompt,
    messages=[{"role": "user", "content": user_content}]
)
result = message.content[0].text
```

### JSON extraction from response

Claude may wrap JSON in markdown code fences. Strip them before parsing:
```python
text = result.strip()
if text.startswith("```"):
    text = text.split("\n", 1)[1]  # remove first line
    text = text.rsplit("```", 1)[0]  # remove last fence
json.loads(text)
```

### CSV output for nested data

For schemas with arrays (like line_items), flatten by repeating top-level fields per array row, or output the array as a separate CSV section.

## Challenges & Solutions

To be filled in during implementation.
