resource "local_file" "example" {
  filename = "hello.txt"
  content  = "Hello from Terraform!"
}
