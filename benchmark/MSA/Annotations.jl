# PF00501 in Pfam 30.0 has 3560 columns, 423 sin inserts
let seq = replace("""
    ........................................................................................
    ........................................................................................
    .m-----.----...--.---..--..........................-------....-..-..-.....-....-....-...
    ......-....-....-....-.....-.......-........-..........-........-..............-....-...
    ............-........G..............V......E.............K.............G.........D.I....
    ...............I.G.......L....K..........G...................R....N........V............
    .P......E..............W.....L.........I..A......D.L.......G..V...Q.........M.....A.....
    ..........G...G......C....S.....L.....N......L.P.Y......................................
    ........Q.Q..K.E..................E...I.....M...V...D.......L.....L....H......E.....I...
    ....G.......T.......-....-....--..........................--..........................-.
    -.--..-..-.......--..-....-.....-.....-.....-......-......-.........-......-........-...
    ....-.....-........-......-........-.......-.......-.......-.........-......-......-....
    ....-....-........-..........-......-........-....-...-..-..-.-.-..-.--.---........---..
    ........................................................................................
    .........................................----.-.--.-......-.-.-.-...-....-.....-...-....
    ..-............-...............-...........-.......-...........-......-.........-.......
    ...-............-...............-.................-.......-.....-.....-...---...........
    ...........--.-.--.-.--.........----.......--..-.--.....................................
    ...--...-.-....--..-....-..-...-...-....-..-....-..-..................-....-....-.-...-.
    ...-....-............-..........-.....-..........-.........-......-............-......-.
    ...-.....-.......-............-.......-...........-......-......-....--..........----...
    ..........................-..-.-..-.........-...........-.........-...........-.........
    -......-.......-.........-......-...-...-..........-...-....-..--..--...................
    ..........--..-.-.---..-.............-----..............................................
    .....................................................................................---
    ...................................-...--..-............................................
    ........................................................................................
    .............................................-.....-...........................-.......-
    -..-...-...-....-....-......-.........-..-...-...-..-..-..-.----........................
    ...................--.-..-..-.-....-..........-.....-.-.-----........--.................
    ...............................................................---.---.-...-...-.-.-....
    .-...-.....-........................--.....-....................................-....-..
    -...-...-..-......-....-..............-.....-.......-........-.......-...-..-.-......-..
    ......................................................--.--..........-.-.............-..
    -..........-....-.....-..-.............-.................-..-............-.............-
    ......-....-.........-...-..................-...--...................-...-..-..-...--..-
    .......................................................-....--..-.-...-...-...-..-..---.
    ...-..-..............-..........-...-................................-...-....-.-..-..-.
    -.-...-..-..-----vvys...................................................................
    ........................................................................................
    ........................................
    """, '\n' => ""),
    mask = convert(BitArray, Bool[isuppercase(char) || char == '-' for char in seq]),
    indexes = collect(eachindex(seq))[mask],
    annot = Annotations()

    setannotresidue!(annot, "K1PKS6_CRAGI/1-58", "SEQ", seq)

    SUITE["MSA"]["Annotations"]["filtercolumns"]["boolean mask"] = @benchmarkable filtercolumns!(copy($annot), $mask)
    SUITE["MSA"]["Annotations"]["filtercolumns"]["index array"] = @benchmarkable filtercolumns!(copy($annot), $indexes)
end
