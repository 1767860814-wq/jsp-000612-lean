#!/usr/bin/env python3
"""Finite sanity checks, independently coded in Python; NOT a general proof.

No Lean API is used. Exhaustive backtracking decides small colorability;
exhaustive cuts compute the exact edge-bipartization number. This helps review
the mathematical interpretation of the formal construction, not kernel soundness.
"""
from __future__ import annotations
import hashlib
import itertools
import json
import math
import time
from pathlib import Path

Vertex = tuple[str, int]
Edge = tuple[int, int]

def construction(q: int, n: int) -> tuple[list[Vertex], set[Edge]]:
    assert q >= 2 and n >= 0
    vs = ([('A', i) for i in range(q)] + [('X', i) for i in range(n+1)]
          + [('Y', i) for i in range(n)] + [('B', i) for i in range(q)])
    ix = {v: i for i, v in enumerate(vs)}
    es: set[Edge] = set()
    def add(a: Vertex, b: Vertex) -> None:
        x, y = ix[a], ix[b]
        assert x != y
        es.add((min(x, y), max(x, y)))
    for i in range(q):
        for j in range(i+1, q): add(('A', i), ('A', j))
        for j in range(q):
            if i != j: add(('A', i), ('B', j))
        if i >= 2:
            for j in range(n): add(('A', i), ('Y', j))
            for j in range(n+1): add(('B', i), ('X', j))
    for j in range(n):
        add(('X', j), ('Y', j)); add(('X', j+1), ('Y', j))
    add(('X', 0), ('B', 0)); add(('X', n), ('B', 1))
    return vs, es

def coloring(vertices: set[int], edges: set[Edge], k: int) -> dict[int, int] | None:
    """Exact search. Color-name symmetry fixes the first used color to zero."""
    adj = {v: set() for v in vertices}
    for a, b in edges:
        assert a in vertices and b in vertices
        adj[a].add(b); adj[b].add(a)
    cs: dict[int, int] = {}
    def visit(max_used: int) -> dict[int, int] | None:
        if len(cs) == len(vertices): return dict(cs)
        v = max(vertices-cs.keys(), key=lambda u: (
            len({cs[w] for w in adj[u] if w in cs}), len(adj[u]), -u))
        forbidden = {cs[w] for w in adj[v] if w in cs}
        for c in range(min(k, max_used + 2)):
            if c not in forbidden:
                cs[v] = c
                got = visit(max(max_used, c))
                if got is not None: return got
                del cs[v]
        return None
    return visit(-1)

def critical_core(vertices: set[int], edges: set[Edge], q: int) -> tuple[set[int], set[Edge]]:
    vertices, edges = set(vertices), set(edges)
    changed = True
    while changed:
        changed = False
        for v in sorted(vertices):
            w = vertices - {v}; f = {e for e in edges if v not in e}
            if coloring(w, f, q) is None:
                vertices, edges, changed = w, f, True
                break
        if changed: continue
        for e in sorted(edges):
            f = edges - {e}
            if coloring(vertices, f, q) is None:
                edges, changed = f, True
                break
    return vertices, edges

def exact_bipartization(vertices: set[int], edges: set[Edge]) -> tuple[int, list[int], int]:
    """Enumerate every cut with the first vertex fixed to side zero."""
    vv = sorted(vertices); index = {v: i for i, v in enumerate(vv)}
    adj: list[list[int]] = [[] for _ in vv]
    for a, b in edges:
        a, b = index[a], index[b]; adj[a].append(b); adj[b].append(a)
    sides = [0]*len(vv); best, current, best_sides = 0, 0, sides[:]
    total = 1 << max(0, len(vv)-1)
    for t in range(1, total):
        v = (t & -t).bit_length()  # Gray-code bit0 maps to vertex1.
        crossed = sum(sides[v] != sides[w] for w in adj[v])
        current += len(adj[v]) - 2*crossed
        sides[v] ^= 1
        if current > best: best, best_sides = current, sides[:]
    return len(edges)-best, best_sides, total

def run() -> dict:
    start = time.monotonic(); results = []
    for q, n in itertools.product(range(2, 6), range(4)):
        labels, es = construction(q, n); vs = set(range(len(labels)))
        assert coloring(vs, es, q) is None
        assert coloring(vs, es, q+1) is not None
        for t in range(n+1):
            missing = labels.index(('X', t))
            assert coloring(vs-{missing}, {e for e in es if missing not in e}, q) is not None
        cv, ce = critical_core(vs, es, q)
        assert coloring(cv, ce, q) is None
        assert coloring(cv, ce, q+1) is not None
        assert all(labels.index(('X', t)) in cv for t in range(n+1))
        for v in cv:
            assert coloring(cv-{v}, {e for e in ce if v not in e}, q) is not None
        for e in ce:
            assert coloring(cv, ce-{e}, q) is not None
        palette = {e for e in ce if all(labels[v][0] == 'A' for v in e)}
        assert len(palette) <= math.comb(q, 2)
        assert coloring(cv, ce-palette, 2) is not None
        optimum, cut, ncuts = exact_bipartization(cv, ce)
        assert 0 < optimum <= len(palette)
        assert sum(cut[sorted(cv).index(a)] == cut[sorted(cv).index(b)] for a,b in ce) == optimum
        result = dict(q=q, k=q+1, chain_length=n, raw_vertices=len(vs),
                      raw_edges=len(es), core_vertex_indices=sorted(cv),
                      vertex_labels=labels, core_edges=sorted(ce),
                      palette_deleted_edges=sorted(palette),
                      exact_bipartization=optimum, maxcut_sides=cut,
                      enumerated_cuts=ncuts, all_checks_passed=True)
        results.append(result)
        print(f'q={q} n={n}: core={len(cv)} vertices, {len(ce)} edges, exact deletions={optimum}', flush=True)
    return dict(description='16 exact finite tests, not a proof for general q,n or an independent Lean checker',
                cases=results, total_cases=len(results),
                total_cuts_enumerated=sum(x['enumerated_cuts'] for x in results),
                seconds=round(time.monotonic()-start, 3),
                script_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest())

if __name__ == '__main__':
    import argparse
    ap = argparse.ArgumentParser(description='Exact finite sanity checks, not a general proof.')
    ap.add_argument('--output-dir', type=Path, default=Path('reproduction'))
    args = ap.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    output = run()
    (args.output_dir/'small_graph_checks.json').write_text(json.dumps(output, indent=2)+'\n')
    print('FINITE_SANITY_CHECKS: PASS')
