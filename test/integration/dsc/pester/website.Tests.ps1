describe 'DSC Configuration' {
  context 'Clowns' {
    $output = irm 'http://localhost:80'
    
    it 'is listening on port 80' {
      $output | Should Not BeNullOrEmpty  
    }
    it 'matches "We Love Clowns"' {
      $output | should match 'We Love Clowns'
    }
  }
  
  context 'Clowns' {
    $output = irm 'http://localhost:81'
    
    it 'is listening on port 81' {
      $output | Should Not BeNullOrEmpty  
    }
    it 'matches "We Love Bears"' {
      $output | should match 'We Love Bears'
    }
  }
}