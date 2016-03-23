describe 'Chef with PowerShell' {
  context 'Clowns' {
    irm 'http://localhost:80' -outfile testdrive:/test.html
    
    it 'is listening on port 80' {
      gi testdrive:/test.html | Should Not BeNullOrEmpty  
    }
    it 'matches "We Love Clowns"' {
      gi testdrive:/test.html | should contain 'We Love Clowns'
    }
  }
  
  context 'Clowns' {
    irm 'http://localhost:81' -outfile testdrive:/test.html
    
    it 'is listening on port 81' {
      gi testdrive:/test.html | Should Not BeNullOrEmpty  
    }
    it 'matches "We Love Bears"' {
      gi testdrive:/test.html | should contain 'We Love Bears'
    }
  }
}