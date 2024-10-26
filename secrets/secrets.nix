let
  systems = {
    server = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMvsO5p2Dk04qOE4pmTfPe8v+WM1KCf0r+RvFsj1TJ8M";
  };
  users = {
    # PS: Benin's key is different than the SSH key he uses to login in the server, blame age + GPG
    benevides = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDR6iSCIEB9Ue5dL3KF/zRYhsoUlwuCDoozEKWTONIh1 leto@caladan";
    kanagawa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDZudUl8jgFsOYouFL2jXFsADyDSKM0f8k/yCyVwlTMv2O3KTAN58OZcQP0NvaCE1xf0c8Z73sBDQE0LZcCuYvJv3Qfuiur2TOr0YgllnUz9XdkFWBNLykfcuOyo7Lvk0BQxXHJr2ADJVvfLRoaSpubYI40KYe2BJUXtwjUcLEUW8Pd9XknI59hCmgdJpWxotCWimGW5I+r8S5zEdTtMoJWMdDaAgzbw5AL+d227wTL0TKwA1LnCkAISgCCYcUGKG78Q8At1/gN/Q9Vl/v+CR9zYWiPgZihk2aK2LiYPPQbu5hhISyEnnJSIojDhZjCib+4Dt93bfKwMMKJxMF9XFeONINkecCyMOIIcfoGzRPoZNRyjc+TbHc84YuaizmJCHgD17dBnmxwZ75rMZHaKtGq4QJ+phP9bwP9oqAaTdDhFGcr1Ia4ozW2t1T3spDiVC3S5AxiwERLO15IDQwN8plJrIdR2lsQAs4dU3/uA5XEmcnPFVMy32fcKlUwJDMgGmM= mcosta@Marcoss-MacBook-Pro.local";
    lemos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMTVKqj451P0oYzmVTFg4J2Y5F3+iM0LsVxKYbCkDuit";
    marinho = "ssh-rsa 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 silver@masu";
    magueta = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCpwjT/R9RMr6KY6iPEwIJzAielyh8fet+GGajzcUMcKouF8jKpIj0dPLhLrUYrYhtJ1fiOYQ3yOImeRb58GxBdobJK7oMt2rNydZVkdXa0XHlhPYxRoA6vxW7gwUBE/vlsCU0TqH4o9TZIsg+jUW9+ZfKdfsVw7XZ7ZqD0zaTeDf+eNKIdhofs6/i5NAMR2d1rZU3yzKGP2DqgflcQa/jlplKhNX2CxCEYuh6eLg/0JYk6Cuj+dlL1lrryFLqK+wsLVqjjJEhWa9p+/kGHfd3PQ1mVEIlomZYODSwUGtaf/282TwZt1RlYZcMJSkZ1P6KwwPp2s4s5QzGfIAX9YeoMXaedNQOqVG+Sshg1VzV2Xrr1EFjbON8t7eKMljp39kUe33u25A9DwYjWFDHaEWJYjKnjQE2kT63oAyYxvBUpG/bfFZSnIKRUUZMzbe9gD+GDXrKuxaEKq2XDkPSoBbtSyDOVSD8rQW8t0UAgzNqvkKAvn4aSWa8eZu7hFDwhZGnt3qV60nksK2zd/0y0KV6Vl+hT/yEycWCq/cEfbIrSYHK7z/+JRWLjpNeEMikHzOy96FUmn2yS7xX+Kbi2VU6oCDkgt1g2MHqCZCe6MfkNgHUdJzYfndJfNxZqc+pS2ytJm5cGzfgVcZG8ni5hprVDKbPkNhM+VwFpJ0nmQ4Wq2Q== (none)";
  };
  everyone = builtins.attrValues systems ++ builtins.attrValues users;
in
{
  "pg_mp.age".publicKeys = everyone;
}
