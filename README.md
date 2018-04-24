# Starlight Stage Uptime Chart Generator
## Explanation
  uptime graph of starlight stage skill activation.

## Restriction
- does not take count of current HP
- does not take count maximum power of valued skills such as SU vs SSU (OL) vs SSSU (CC)
- assuming every input is correct.

## Input Format
```
card_amount [card_data ...card_amount times] chart_data chart_name

card_data  ::= "m" card_id skill_level name | card_raw
card_raw   ::= any_char card_id interval base_uptime skill_level skill_id name

chart_data ::= "f" set_id diff_id | chart_raw
chart_raw  ::= any_char notes_amount [note_time ...notes_amount times]
chart_name ::= [whole_line] string
```

## Examples
1. `2018 04 22 ver.` Prototype
  ![](https://cdn.discordapp.com/attachments/338119821868662785/437625369835732994/unknown.png)
  cards that used on example can be seen in `debug_uptime.md`
2. ... and so on.

## Requirements
- Ruby 2.3.0
- Image Magick

