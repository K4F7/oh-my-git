extends Reference

# Known-good command sequences for every level, typed into the in-game
# terminal by the level harness. An entry can also be a Dictionary
# {"cmd": ..., "editor": ...}: the command is expected to open the in-game
# text editor (via fake-editor), whose buffer is then replaced by "editor"
# (or kept as-is when "editor" is null) and saved; "shows" must appear in the
# buffer the editor opened with. "reorder" instead permutes
# the non-comment lines of the buffer (used for interactive rebase todo lists).
const SOLUTIONS = {
	"intro/risky": ["echo '- Because it is fun' >> form.txt"],
	"intro/copies": ["echo '- Because it is fun' >> form2_really_final.txt"],
	"intro/init": ["git init"],
	"intro/cli": ["git init"],
	"intro/commit": [
		"git add .",
		"git commit -m 'Full glass'",
		"echo 'The glass is empty.' > glass",
		{"cmd": "git add .; git commit", "editor": "Drink the water\n"},
	],
	"intro/remote": [
		"git pull",
		"echo '- Me' >> students",
		"git commit -am 'Add me'",
		"git push",
	],
	"files/files-delete": ["rm tiny_web big_web thick_web"],
	"files/files-add": [
		"echo 'A yellow chair.' > chair",
		"echo 'A yellow table.' > table",
	],
	"branches/checkout-commit": [
		"git checkout HEAD@{1}",
		"git checkout HEAD^^ piggy_bank",
		"echo 'A young girl with brown, curly hair.' > little_sister",
		"git commit -am 'Give the coins back'",
	],
	"branches/fork": [
		"git checkout HEAD~3",
		"echo 'Looks satisfied.' > cage/lion",
		"git commit -am 'Feed the lion'",
	],
	"branches/branch-create": [
		"git branch concert HEAD@{1}",
		"git branch birthday HEAD@{3}",
	],
	"branches/grow": [
		"git checkout --detach birthday",
		"echo 'You eat cake.' >> you",
		"git commit -am 'Cake'",
		"git checkout concert",
		"echo 'You dance.' >> you",
		"git commit -am 'Dance'",
	],
	"branches/branch-remove": ["git branch -D friend music ice-cream"],
	"branches/reorder": [
		"git branch tmp coffee",
		"git branch -f coffee baguette",
		"git branch -f baguette tmp",
		"git branch -D tmp",
		"git checkout donut",
		"sed -i.bak 's/You have a donut/You ate a donut/' you",
		"rm you.bak",
		"git commit -am 'Eat the donut'",
	],
	"merge/merge": [
		"git merge -m 'Baguette' $(git log -g -1 --format=%H --grep='eat the baguette')",
		"git merge -m 'Coffee' $(git log -g -1 --format=%H --grep='drink the coffee')",
	],
	"merge/conflict": [
		"git reset --hard pancakes",
		"git merge muesli",
		"printf 'Had pancakes and muesli for breakfast.\\n\\nIs at work.\\n' > sam",
		{"cmd": "git add .; git commit", "editor": null},
	],
	"index/compare": [
		"git checkout step-by-step",
		"echo 'It is beeping loudly!' > smoke_detector",
		"git commit -am 'Alarm'",
	],
	"index/new": ["git add candle", "git commit -m 'Add candle'"],
	"index/change": [
		"echo 'The candle has been blown out.' > candle",
		"git add candle",
		"git commit -m 'Blow out the candle'",
	],
	"index/reset": [
		"git reset green_candle blue_candle",
		"git commit -m 'Blow out the red candle'",
	],
	"index/steps": [
		"echo 'The hammer falls over.' > hammer",
		"echo 'The bottle breaks.' > bottle",
		"echo 'The sugar cube dissolves.' > sugar_cube",
		"git add hammer",
		"git commit -m 'Hammer'",
		"git add bottle",
		"git commit -m 'Bottle'",
		"git add sugar_cube",
		"git commit -m 'Sugar'",
	],
	"remotes/friend": [
		"git pull",
		"echo 'Line 3' >> essay",
		"git commit -am 'Line 3'",
		"git push",
		"git pull",
		"echo 'Line 5' >> essay",
		"git commit -am 'Line 5'",
		"git push",
	],
	"remotes/problems": [
		"git commit -am 'Green'",
		"git pull",
		"echo 'The bike shed should be teal' > file",
		"git add file",
		"git commit -m 'Compromise'",
		"git push",
	],
	"changing-the-past/rebase": [
		"git checkout coffee",
		"git rebase baguette",
		"git checkout donut",
		"git rebase coffee",
		"git checkout main",
		"git merge donut",
	],
	"changing-the-past/reorder": [
		{"cmd": "git rebase -i HEAD~4", "reorder": [2, 1, 0, 3]},
	],
	"shit-happens/restore-a-file": ["git checkout essay"],
	"shit-happens/restore-a-file-from-the-past": [
		"git checkout HEAD^ essay",
		"git commit -m 'Restore the good version'",
	],
	"shit-happens/bad-commit": [
		"git reset HEAD^",
		"echo '1 2 3 4 5 6 7 8 9 10' > numbers",
		"git commit -am 'More numbers'",
	],
	"shit-happens/pushed-something-broken": [
		"git revert --no-edit HEAD~1 || true",
		"printf 'this is fine\\n\\nthis is also fine\\n\\n?\\n\\nthis is fine again\\n' > text",
		"git add text",
		"git -c core.editor=true revert --continue || true",
		"git push",
	],
	"shit-happens/reflog": ["git checkout 3"],
	"workflows/pr": [
		"git clone ../friend .",
		"git checkout -b solution",
		"echo '2 + 3 = 5' > file",
		"git commit -am 'Fix the sum'",
		"git tag pr",
	],
	"bisect/bisect": [
		"git bisect start main main~29",
		"git bisect run grep -q 'still have your key' you",
		"git tag last-good refs/bisect/bad~1",
		"git bisect reset",
		"git reset --hard last-good",
		"git tag -d last-good",
	],
	"stash/stash": ["git stash"],
	"stash/stash-pop": ["git stash pop"],
	"stash/stash-clear": ["git stash clear"],
	"stash/stash-branch": ["git stash branch flour"],
	"stash/stash-merge": [
		"git commit -m 'Salt'",
		"git stash pop || true",
		"printf 'Apple Pie:\\n- 4 Apples\\n- 500g Flour\\n- Pinch of Salt\\n' > recipe",
		"git add recipe",
		"git commit -m 'Flour and salt'",
		"git stash drop",
	],
	"tags/add-tag": ["git tag v1"],
	"tags/remove-tag": ["git tag -d v1 v2 v3"],
	"tags/add-tag-later": ["git tag v1 HEAD~1"],
	"tags/remote-tag": [
		"git fetch --tags",
		"git tag v2",
		"git push friend v2",
	],
	"sandbox/empty": ["git init", "git commit --allow-empty -m 'empty'"],
	"sandbox/remote": ["git pull", "git log --oneline"],
	"sandbox/three-commits": ["git checkout not_main", "git log --oneline"],
}

# Levels that intentionally have no win conditions.
const NO_GOAL_LEVELS = ["sandbox/empty", "sandbox/remote", "sandbox/three-commits"]

# Exploratory sessions that poke at the visualisation and file browser with
# unusual but legal input. Each entry names the level to start from and the
# steps to type; the run fails if the game quits (helpers.crash()), a command
# times out, the terminal output lacks "expect" or contains "reject".
const EXPLORATORY = {
	"hint-script": {"level": "sandbox/empty", "steps": ["hint '你好，hint'"], "reject": "Can't call method", "notification": "你好，hint"},
	"editor-non-ascii": {"level": "sandbox/three-commits", "steps": [{"cmd": "echo x >> you; git commit -a", "editor": "喝水 ☕\n"}, "git log -1 --format=%s"], "expect": "$ git log -1 --format=%s\n喝水 ☕", "reject": "did not conform to UTF-8"},
	"editor-shows-non-ascii": {"level": "sandbox/three-commits", "steps": ["echo '中文内容' > you", {"cmd": "fake-editor you", "editor": null, "shows": "中文内容"}, "cat you"], "expect": "$ cat you\n中文内容"},
	"space-in-filename": {"level": "sandbox/three-commits", "steps": ["touch 'a b'", "git add .", "git commit -m space"]},
	"tag-on-tree": {"level": "sandbox/three-commits", "steps": ["git tag tree-tag HEAD^{tree}"]},
	"annotated-tag": {"level": "sandbox/three-commits", "steps": ["git tag -a v1 -m 'release one'"]},
	"orphan-branch": {"level": "sandbox/three-commits", "steps": ["git checkout --orphan fresh"]},
	"dangling-head": {"level": "sandbox/three-commits", "steps": ["git symbolic-ref HEAD refs/heads/nowhere"]},
	"delete-git-dir": {"level": "sandbox/three-commits", "steps": ["rm -rf .git"]},
	"merge-conflict-state": {"level": "sandbox/three-commits", "steps": ["git checkout -b side HEAD~1", "echo other > you", "git commit -am other", "git merge main || true"]},
	"rebase-in-progress": {"level": "sandbox/three-commits", "steps": ["git checkout -b side2 HEAD~1", "echo other > you", "git commit -am other", "git rebase main || true"]},
	"stash-ref": {"level": "sandbox/three-commits", "steps": ["echo change >> you", "git stash"]},
	"subdirectory": {"level": "sandbox/three-commits", "steps": ["mkdir -p dir/sub", "echo x > dir/sub/file", "git add .", "git commit -m dir"]},
	"empty-repo": {"level": "sandbox/empty", "steps": ["git init", "git status"]},
	"long-output": {"level": "bisect/bisect", "steps": ["git log"]},
}
