# digest_network.py
# written by Chris Coletta for BIOF 518
# takes as input a file containing node pairs (edges) one per line
# and calculates statistics such as diameter and clustering coefficients

import re
from copy import deepcopy
import sys

debug = 0

#================================================================
class AutoVivification(dict):
    """This is just an convenience class which is an implementation of
		Perl's autovivification functionality."""

    def __getitem__(self, item):
        try:
            return dict.__getitem__(self, item)
        except KeyError:
            value = self[item] = type(self)()
            return value


#================================================================
def PrintNetwork( the_network ):
	"""PrintNetwork takes a Python dictionary containing nodes and edges
	and just prints out the information in node order from smallest number of edges to largest"""

	nodecount = 0
	for k in sorted( the_network.keys(), lambda x,y: cmp( len(the_network[x]), len(the_network[y]) ) ):
		nodecount += 1
		print 'node {} has edges with {} members: {}'.format(k, len(the_network[k]), the_network[k])
	# how many nodes are in the network
	print '\nNetwork has {} nodes\n'.format( nodecount )


#================================================================
def NetworkWithoutMe( me, the_network ):
	"""NetworkWithoutMe prunes the node "me" from the inputted network and returns
	the smaller pruned network"""

	if debug: print "\t deleting me: {}".format(me)
	smaller_network = deepcopy( the_network )
	# first delete any of my neighbors that are only connected to me and my neighbors
	# meaning, delete neighbor if neighbor's edges is a subset of my edges
	my_neighbors = the_network[me]
	if debug: print "\t{}'s neighbors: {}".format( me, my_neighbors )
	for edge in my_neighbors:
		# remove me from my neighbor's neighbor list since I'm going anyway
		if debug: print "\t{}'s neighbor {}:".format(me, edge)
		if debug: print "\t\t{}'s neighbors: {}".format(edge, smaller_network[edge])
		smaller_network[edge].remove(me)
		if smaller_network[edge].issubset( my_neighbors ):
			if debug: print "\t\ti can delete {} because {} is subset of {}".format( edge, smaller_network[edge], my_neighbors )
			for departing_neighbors_neighbor in smaller_network[edge]:
				smaller_network[departing_neighbors_neighbor].remove( edge )
			del smaller_network[edge]
	del smaller_network[me]
	return smaller_network


#================================================================
def GetDistance( this_node, that_node, orig_network, depth=0):
	"""GetDistance returns the shortest distance between two nodes"""

	the_network = orig_network.copy()
	if debug: print "depth {}: calculating distance between {} and {}".format(depth, this_node, that_node )
	if this_node == that_node:
		if debug: print "identity"
		return 0

	# check to see if that_node is in this_node's list of edges
	if debug: print "check if {} is in {}'s set of edges: {}".format(that_node, this_node, node_dict[this_node] )
	my_neighbors = the_network[this_node].copy()
	for link in the_network[this_node]:
		if link == that_node:
			if debug: print "******FOUND:{} has edge with {}".format( this_node, that_node )
			return 1
	
	# if not, remove me from the network and continue to find dists from my viable neighbors
	if debug: print "removing {} from depth {} network (size {})".format(this_node, depth, len(the_network))
	smaller_network = NetworkWithoutMe( this_node, the_network )
	
	# remove any nodes from my_neighbors that got pruned from the smaller network
	set_of_nodes_in_smaller_netw = set()
	for node in smaller_network.keys():
		set_of_nodes_in_smaller_netw.add(node)
	
	my_neighbors.intersection_update( set_of_nodes_in_smaller_netw )

	min_dist = 999
	for link in my_neighbors:
		link_dist = GetDistance( link, that_node, smaller_network, depth+1)
		if link_dist < min_dist:
			min_dist = link_dist
	return 1 + min_dist


#================================================================
def GetClusteringCoefficient( node, the_network ):
	debugg = 1
	if debugg: print "\n"
	if debugg: print "node: {}".format(node)
	my_neighbors = the_network[node]
	if debugg: print 'neighbors "Nv": {}'.format( my_neighbors)
	num_neighbors = len( my_neighbors )
	if debugg: print "num_neighbors: {}".format(num_neighbors)
	edges_among_neighbors = 0
	for neighbor in my_neighbors:
		neighbors_neighbors = the_network[ neighbor ]
		shared = neighbors_neighbors & my_neighbors
		if debugg: print "neighbors of {} that are also neighbors of {}: {}".format( node, neighbor, shared )
		edges_among_neighbors += len( shared )
	edges_among_neighbors /= 2
	if debugg: print 'non-redundant edges among all neighbors "E(Nv): {}'.format(edges_among_neighbors)
	value = float()
	if num_neighbors > 1:
		# divide by 2 first since every edge is counted twice a->b and b->a
		value = 2 * float(edges_among_neighbors) / ( num_neighbors * ( num_neighbors - 1) )
		if debugg: print " coeff = 2 * {0} / ( {1} * ( {1} -1) ) = {2}".format(edges_among_neighbors, num_neighbors, value )
	else:
		value = 0
	return value

def CalculateClusteringCoeffsForNetwork( the_network ):
	coeffs = {}
	for node in the_network.keys():
		coeffs[node] = GetClusteringCoefficient( node, the_network )
	return coeffs


#================================================================
# MAIN PROGRAM
#================================================================
def main():
	
	input_filename = sys.argv[1]
	input_file = open( input_filename, 'r' )
	lines = input_file.read().splitlines()
	input_file.close()

	node_dict = dict()

	for line in lines:
		m = re.search( r'^(\w+)\s(\w+)', line)
		if m:
			if debug: print m.groups()
			node1 = m.group(1)
			node2 = m.group(2)
			if debug: print 'node1: {} node2: {}\n'.format( node1, node2 )
			if node1 in node_dict:
				node_dict[node1].add(node2)
			else:
				node_dict[node1] = set()
				node_dict[node1].add(node2)

			if node2 in node_dict:
				node_dict[node2].add(node1)
			else:
				node_dict[node2] = set()
				node_dict[node2].add(node1)

	PrintNetwork( node_dict )

	distance_matrix = AutoVivification()

	rows = sorted(deepcopy( node_dict.keys() ) )
	report = ""
	for key in rows:
		report += "{}\t".format(key)
	report += "\n"


	already_done = set()

	num_dists = 0
	avg = 0
	for row in rows:
		for col in rows:
			if col not in already_done:
				dist = GetDistance( row, col, node_dict )
				print "++++++distance betw {} and {} is {}".format(row, col, dist)
				distance_matrix[row][col] = dist
				report += "{}\t".format( dist )
				if dist != 0:
					num_dists += 1
					avg += dist
			else:
				report += "\t"
		report += "{}\n".format(row)
		already_done.add(row)



	print report

	print "\ndiameter = {}\n".format( float(avg) / float(num_dists) )

#print distance_matrix
	if debug: 
		for key in rows:
			print "{}\n".format(distance_matrix[key])

	clustering_coeffs = CalculateClusteringCoeffsForNetwork( node_dict )
	print "\n\nClustering Coefficients:"
	for node in sorted( clustering_coeffs.keys(), lambda x,y: cmp( clustering_coeffs[x], clustering_coeffs[y]) ):
		print "{}:\t{}".format(node, clustering_coeffs[node])

if __name__ == "__main__":
    main()
