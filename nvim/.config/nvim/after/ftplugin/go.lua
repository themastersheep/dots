-- Define the syllables
local syllables_2 = { 'ka', 'ki', 'ku', 'ke', 'ko', 'ga', 'gi', 'gu', 'ge', 'go',
    'sa', 'su', 'se', 'so', 'za', 'ji', 'zu', 'ze', 'zo',
    'ta', 'te', 'to', 'da', 'de', 'do', 'na', 'ni', 'nu',
    'ne', 'no', 'ha', 'hi', 'fu', 'he', 'ho', 'ba', 'bi', 'bu',
    'be', 'bo', 'pa', 'pi', 'pu', 'pe', 'po', 'ma', 'mi', 'mu',
    'me', 'mo', 'ya', 'yu', 'yo', 'ra', 'ri', 'ru', 're', 'ro',
    'wa', 'wo' }
local syllables_3 = { 'shi', 'tsu', 'chi', 'nai', 'nei', 'nou', 'sai', 'sei', 'sou',
    'tai', 'tei', 'tou', 'hai', 'hei', 'hou', 'mai', 'mei', 'mou',
    'yai', 'you', 'rai', 'rei', 'rou', 'wai', 'wou',
    'jya', 'jyu', 'jyo', 'gya', 'gyu', 'gyo', 'nya', 'nyu', 'nyo',
    'hya', 'hyu', 'hyo', 'bya', 'byu', 'byo', 'pya', 'pyu', 'pyo',
    'mya', 'myu', 'myo', 'rya', 'ryu', 'ryo' }

-- Function to get a random word
local function get_word()
    return syllables_3[math.random(#syllables_3)] .. syllables_2[math.random(#syllables_2)]
end

vim.keymap.set("n", "<leader>rw", function()
    local snip = "fmt.Printf(\"" .. get_word() .. " %v\\n\", ${1})"
    vim.cmd('normal! o ')
    vim.snippet.expand(snip)
end, { buffer = true, desc = "Printf debugging <cword>" })

vim.keymap.set("n", "<leader>rl", function()
    local snip = "fmt.Println(\"" .. get_word() .. "\")"
    vim.cmd('normal! o ') -- new line please
    vim.snippet.expand(snip)
end, { buffer = true, desc = "Printf debugging <cword>" })
