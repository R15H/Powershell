
BeforeAll {
    #. $PSCommandPath.Replace('.Tests.ps1','.ps1')
    . $PSScriptRoot/ConvertTo-NamedPath.ps1
}
Describe "NamedPaths" {
    Describe 'Root drive, no named paths' {
        It "Root Drive" {
            ConvertTo-NamedPath "C:\" | Should -Be @($null)
        }

        It "Alias 1 deep" {
            ConvertTo-NamedPath "C:\s\"  | Should -Be @("[s]")
        }

        It "Default home folder alias" {
            ConvertTo-NamedPath $HOME | Should -Be @("[~]")
        }
    }
    Describe 'Add new-aliases' {
        It "should add a new alias" {
            Add-NamedPath "$HOME\Downloads" '⬇️'
            ConvertTo-NamedPath "$home\Downloads" | Should -Be @('[⬇️]')
        }

        It "inside alias folder"{
            Add-NamedPath "$HOME\Documents" '📜'
            ConvertTo-NamedPath "$HOME\Documents\some\cool\path" | Should -Be @('[📜]', 'some', 'cool', 'path')
        }

    }
    
}
Describe "Add-NamedPath" {
    It 'should return alias' {
        Add-NamedPath '$Home/Downloads' '⬇️' -PassThru| Should -Be '[⬇️]'
    }
}