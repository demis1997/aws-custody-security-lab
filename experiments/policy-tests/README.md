# Infrastructure policy tests

The executable checks are the `.tftest.hcl` files under each Terraform environment. Every provider is mocked and every run uses `command = plan`. They inspect actual generated policy JSON and resource attributes, and include negative tests for missing deployment acknowledgement, public peers and wildcard operator trust. The standard validation runner executes them without cloud credentials.

No live IAM authorization verdict, S3 deletion attempt, CloudTrail delivery or network packet test is implied by a passing plan assertion.
