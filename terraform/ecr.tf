resource "aws_ecr_repository" "myapp" {
	name = "devops-journey-myapp"
	image_tag_mutability = "MUTABLE"
        force_delete          = true

	tags={
	  Name = "devops-journey-myapp"
	}
}
