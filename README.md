# hub-fooler

Create superstar repositories.

## Usage

Fork the hub-fooler repo, run the fooler script, then push the fooler repo's master branch to a github branch:

```
  ./hub-fooler.sh
  git -C /tmp/hub-fooler.sh.QvQt/repo push git@github.com:${user}/hub-fooler.git master:fooler
  rm -rf /tmp/hub-fooler.sh.QvQt
```

To cleanup remove the remote github branch:

```
  git push git@github.com:${user}/hub-fooler.git :fooler
```

## Help

```
hub-fooler.sh - Generate a superstar git repository.
Usage: hub-fooler.sh [flags]
Option flags:
  -h --help        - Show this help and exit.
  -v --verbose     - Verbose execution.
Level:
  -1 --rock-star   - One commit per day, M-F (default).
  -2 --hero        - One-three commits per day, M-F.
  -3 --untouchable - Two-five commits per day, everyday.
```

## Results

![contributions](contributions.png)
