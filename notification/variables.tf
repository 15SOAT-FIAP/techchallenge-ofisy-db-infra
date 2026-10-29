variable "account_id" {
  description = "Conta AWS esperada; opcional para validação local sem credenciais."
  type        = string
  default     = ""
  validation {
    condition     = var.account_id == "" || can(regex("^[0-9]{12}$", var.account_id))
    error_message = "account_id deve ter 12 dígitos."
  }
}
