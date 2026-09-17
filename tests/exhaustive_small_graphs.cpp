// Independent finite-domain sanity check. Not a proof-assistant kernel.
// Enumerates every labelled simple graph through six vertices.
#include <algorithm>
#include <array>
#include <chrono>
#include <fstream>
#include <iostream>
#include <map>
#include <tuple>
#include <vector>
#include <cassert>
using namespace std;
array<int,64> chromatic_dp(const vector<unsigned>& adj,int n) {
  array<int,64> dp{};array<bool,64> independent{};independent[0]=true;
  for(unsigned s=1;s<(1u<<n);++s){
    unsigned v=__builtin_ctz(s), t=s&(s-1);
    independent[s]=independent[t] && ((adj[v]&t)==0); dp[s]=n+1;
    unsigned bit=s&(~s+1u);
    for(unsigned a=s;a;a=(a-1)&s)
      if((a&bit)&&independent[a]) dp[s]=min(dp[s],1+dp[s^a]);
  }
  return dp;
}
int main(){
  auto start=chrono::steady_clock::now();
  unsigned long long total=0,cuts=0,proper_vertex_checks=0,proper_edge_checks=0;
  map<pair<int,int>,pair<unsigned long long,int>> results;
  ofstream csv("exhaustive_small_graphs.csv");csv<<"n,k,edge_mask,bipartization_min\n";
  for(int n=0;n<=6;++n){
    vector<pair<int,int>> pairs;
    for(int i=0;i<n;++i)for(int j=i+1;j<n;++j)pairs.emplace_back(i,j);
    for(unsigned mask=0;mask<(1u<<pairs.size());++mask){
      ++total;vector<unsigned> adj(n,0);int edges=0;
      for(unsigned i=0;i<pairs.size();++i)if(mask&(1u<<i)){
        auto [u,v]=pairs[i];adj[u]|=1u<<v;adj[v]|=1u<<u;++edges;
      }
      auto dp=chromatic_dp(adj,n);unsigned all=(1u<<n)-1;int k=dp[all];
      assert(k<=n);int least=edges;
      unsigned ways=n?1u<<(n-1):1;
      for(unsigned part=0;part<ways;++part){
        ++cuts;int within=0;
        for(unsigned i=0;i<pairs.size();++i)if(mask&(1u<<i)){
          auto [u,v]=pairs[i];within+=((part>>u&1u)==(part>>v&1u));
        }
        least=min(least,within);
      }
      assert((least==0)==(k<=2));
      if(k<3)continue;
      bool critical=true;
      for(int v=0;v<n;++v){++proper_vertex_checks;if(dp[all^(1u<<v)]>=k){critical=false;break;}}
      if(!critical)continue;
      for(unsigned i=0;i<pairs.size();++i)if(mask&(1u<<i)){
        ++proper_edge_checks;auto [u,v]=pairs[i];adj[u]^=1u<<v;adj[v]^=1u<<u;
        bool fails=chromatic_dp(adj,n)[all]>=k;adj[u]^=1u<<v;adj[v]^=1u<<u;
        if(fails){critical=false;break;}
      }
      if(!critical)continue;
      assert(least>0);auto key=make_pair(n,k);
      if(!results.count(key))results[key]={0,least};
      ++results[key].first;results[key].second=min(results[key].second,least);
      csv<<n<<','<<k<<','<<mask<<','<<least<<'\n';
    }
  }
  cout<<"{\n  \"labelled_graphs\": "<<total<<",\n  \"cuts_enumerated\": "<<cuts
      <<",\n  \"proper_vertex_tests\": "<<proper_vertex_checks<<",\n  \"proper_edge_tests\": "<<proper_edge_checks<<",\n  \"critical_families\": [\n";
  bool first=true;for(auto [key,val]:results){
    if(!first) { cout<<",\n"; }
    first=false;
    cout<<"    {\"n\": "<<key.first<<", \"k\": "<<key.second<<", \"labelled_critical_graphs\": "<<val.first<<", \"minimum_actual_deletions\": "<<val.second<<"}";
  }
  cout<<"\n  ],\n  \"seconds\": "<<chrono::duration<double>(chrono::steady_clock::now()-start).count()<<",\n  \"all_assertions_passed\": true,\n  \"is_independent_lean_checker\": false\n}\n";
}
