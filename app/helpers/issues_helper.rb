module IssuesHelper
	# Adds CSS class to unpublished issues in issues index.
	def unpublished(issue)
        if not issue.published
            " issue-unpublished"
        end
    end
end
