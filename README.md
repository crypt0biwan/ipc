# IPC (ImmortalPlayerCharacter)

The contracts for IPC: [the v0 contract](https://etherscan.io/token/0x4787993750b897fba6aad9e7328fc4f5c126e17c) and [the v1 (official) contract](https://etherscan.io/token/0x011C77fa577c500dEeDaD364b8af9e8540b808C0)

## Metadata

The metadata is for the v1 contract (which is officialy supported by the IPC team). 
Reverse engineering it I was able to generate the metadata based on the attribute seed and the dna properties.
Here's some of the metadata so it's easily to scan when you're looking at a JSON file

### race

```
0 UNKNOWN_RACE
1 ELF
2 HUMAN
3 DWARF
4 ORC
```

### subrace

```
0 UNKNOWN_ELF
1 NIGHT_ELF
2 WOOD_ELF
3 HIGH_ELF
4 SUN_ELF
5 DARK_ELF
6 UNKNOWN_HUMAN
7 MYTHICAL_HUMAN
8 NORDIC_HUMAN
9 EASTERN_HUMAN
10 COASTAL_HUMAN
11 SOUTHERN_HUMAN
12 UNKNOWN_DWARF
13 QUARRY_DWARF
14 MOUNTAIN_DWARF
15 LUMBER_DWARF
16 HILL_DWARF
17 VOLCANO_DWARF
18 UNKNOWN_ORC
19 ASH_ORC
20 SAND_ORC
21 PLAINS_ORC
22 SWAMP_ORC
23 BLOOD_ORC
```

### gender

```
0 UNKNOWN_GENDER
1 FEMALE
2 MALE
3 NONBINARY // Not a default option; Set by owner.
```

### color

```
0 White
1 BlueGrey
2 MidnightBlue
3 Blue
4 DarkBlue
5 BlueBlack
6 Icy
7 Pale
8 Beige
9 Golden
10 Tan
11 LightBrown
12 Brown
13 DarkBrown
14 Obsidian
15 Red
16 Grey
17 Black
18 Ice
19 Green
20 ForestGreen
21 DarkBlueGreen
22 BlueGreen
23 PaleGreen
24 Purple
25 Orange
26 Gold
27 Amber
28 DarkGrey
29 LightYellow
30 Yellow
31 DarkYellow
32 Platinum
33 Blonde
34 Auburn
35 DarkRed
36 MarbledWhite
37 MarbledBlack
```

### handedness

```
0 UNKNOWN_HANDED
1 LEFT_HANDED
2 RIGHT_HANDED
3 AMBIDEXTROUS
```

### height

Some JavaScript code found on their website, easier to just paste the functions :-)

```javascript
function _calculate_elf_height(gender, height_percent)
{
    let height = IPCLib.IPCBaseHeightByRace[IPCLib.IPC_ELF]; // Default.
    if (gender == IPCLib.IPC_MALE) { height += 2; } // Elf Males are 2 inches taller.

    if (height_percent < 5) { return height; }
    else if (height_percent < 35) { return height + 1; }
    else if (height_percent < 60) { return height + 2; }
    else if (height_percent < 95) { return height + 3; }
    else { return height + 4; }
}

function _calculate_human_height(gender, height_percent)
{
    let height = IPCLib.IPCBaseHeightByRace[IPCLib.IPC_HUMAN]; // Default.
    if (gender == IPCLib.IPC_MALE) { height += 4; } // Human Males are 4 inches taller.

    if (height_percent < 5) { return height; }
    else if (height_percent < 10) { return height + 1; }
    else if (height_percent < 15) { return height + 2; }
    else if (height_percent < 25) { return height + 3; }
    else if (height_percent < 40) { return height + 4; }
    else if (height_percent < 55) { return height + 5; }
    else if (height_percent < 65) { return height + 6; }
    else if (height_percent < 75) { return height + 7; }
    else if (height_percent < 85) { return height + 8; }
    else if (height_percent < 90) { return height + 9; }
    else if (height_percent < 95) { return height + 10; }
    else { return height + 11; }
}

function _calculate_dwarf_height(gender, height_percent)
{
    let height = IPCLib.IPCBaseHeightByRace[IPCLib.IPC_DWARF]; // Default.
    if (gender == IPCLib.IPC_MALE) { height += 2; } // Dwarf males are 2 inches taller.

    if (height_percent < 5) { return height; }
    else if (height_percent < 15) { return height + 1; }
    else if (height_percent < 40) { return height + 2; }
    else if (height_percent < 65) { return height + 3; }
    else if (height_percent < 85) { return height + 4; }
    else if (height_percent < 95) { return height + 5; }
    else { return height + 6; }
}

function _calculate_orc_height(gender, height_percent)
{
    let height = IPCLib.IPCBaseHeightByRace[IPCLib.IPC_ORC]; // Default.
    if (gender == IPCLib.IPC_MALE) { height += 4; } // Orc males are 4 inches taller.

    if (height_percent < 5) { return height; }
    else if (height_percent < 10) { return height + 1; }
    else if (height_percent < 15) { return height + 2; }
    else if (height_percent < 25) { return height + 3; }
    else if (height_percent < 40) { return height + 4; }
    else if (height_percent < 55) { return height + 5; }
    else if (height_percent < 65) { return height + 6; }
    else if (height_percent < 75) { return height + 7; }
    else if (height_percent < 85) { return height + 8; }
    else if (height_percent < 90) { return height + 9; }
    else if (height_percent < 95) { return height + 10; }
    else { return height + 11; }
}

function _calculate_height(race, gender, height_value)
{
    let height_percent = _calculate_percent(height_value);

    switch (race)
    {
        case IPCLib.IPC_ELF: return _calculate_elf_height(gender, height_percent);
        case IPCLib.IPC_HUMAN: return _calculate_human_height(gender, height_percent);
        case IPCLib.IPC_DWARF: return _calculate_dwarf_height(gender, height_percent);
    }

    return _calculate_orc_height(gender, height_percent);
}
```

### strength, dexterity, intelligence

```javascript
strength = force + sustain + tolerance
dexterity = speed + precision + reaction
intelligence = memory + processing + reasoning
constitution = healing + fortitude + vitality
```