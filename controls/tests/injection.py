# Fixtures for controls/rules/injection.yaml
#
# STEAL: IGNORE: Deliberately vulnerable by design. Every `ruleid:` line below is a working
# injection that exists so a rule can be asserted against it. Lifting any of it into real
# code ships the exact defect the rule beside it was written to catch.
#
# Run with: semgrep --test --config files/ selftest/
# `ruleid:` asserts the rule fires on the next line. `ok:` asserts it does not.
# The `ok:` cases are the point: a rule that cannot distinguish safe from unsafe
# is not a control, it is noise.

import os
import subprocess


def sql_sinks(cur, user_id):
    # ruleid: runwai-python-sql-string-building
    cur.execute(f"SELECT * FROM users WHERE id = {user_id}")

    # ruleid: runwai-python-sql-string-building
    cur.execute("SELECT * FROM users WHERE id = %s" % user_id)

    # ruleid: runwai-python-sql-string-building
    cur.execute("SELECT * FROM users WHERE name = " + user_id)

    # ruleid: runwai-python-sql-string-building
    cur.execute("SELECT * FROM users WHERE id = {}".format(user_id))

    # ruleid: runwai-python-sql-string-building
    cur.executemany(f"INSERT INTO t VALUES ({user_id})")


def sql_parameterised(cur, user_id):
    # ok: runwai-python-sql-string-building
    cur.execute("SELECT * FROM users WHERE id = %s", (user_id,))

    # ok: runwai-python-sql-string-building
    cur.execute("SELECT * FROM users WHERE id = :id", {"id": user_id})

    # A fully static query is safe regardless of how it is written.
    # ok: runwai-python-sql-string-building
    cur.execute("SELECT count(*) FROM users")


def shell_sinks(name):
    # ruleid: runwai-python-shell-injection
    os.system(f"echo {name}")

    # ruleid: runwai-python-shell-injection
    os.system("echo " + name)

    # ruleid: runwai-python-shell-injection
    subprocess.run(f"ls {name}", shell=True)


def shell_safe(name):
    # ok: runwai-python-shell-injection
    subprocess.run(["ls", name], shell=False)

    # ok: runwai-python-shell-injection
    subprocess.run(["echo", name])

    # A static command with no interpolation is not an injection.
    # ok: runwai-python-shell-injection
    os.system("uptime")
