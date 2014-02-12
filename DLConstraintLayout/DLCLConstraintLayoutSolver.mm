//
//  DLCLConstraintLayoutSolver.mm
//  DLConstraintLayout
//
//  Created by vesche on 4/9/13.
//  Copyright (c) 2013 Regexident. All rights reserved.
//

#import "DLCLConstraintLayoutSolver.h"

#import <QuartzCore/QuartzCore.h>

#import "DLCLConstraint.h"
#import "DLCLConstraint+Protected.h"
#import "CALayer+DLConstraintLayout.h"

#if defined(DLCL_USE_CPP_SOLVER)

#include <set>
#include <vector>
#include <map>
#include <queue>
#include <stdexcept>

#else

#import "DLCLConstraintLayoutNode.h"

#endif

#if defined(DLCL_USE_CPP_SOLVER)

namespace dlcl {
    
    class constraint_layout_node {
        
    public:
        
        using layer_type = CALayer;
        using constraint_type = DLCLConstraint;
        using constraint_struct_type = DLCLConstraintStruct;
        using constraint_struct_vector_type =  std::vector<constraint_struct_type>;
        using node_ptr_set_type = std::set<constraint_layout_node *>;
        using node_pair_type = std::pair<constraint_layout_node, constraint_layout_node>;
        using attribute_type = DLCLConstraintAttribute;
        using axis_type = DLCLConstraintAxis;
        using axis_attribute_type = DLCLConstraintAxisAttribute;
        
        constraint_layout_node(const layer_type *layer_ptr, axis_type axis) : layer_ptr(layer_ptr), axis(axis) {
            // intentionally left blank
        }
        
        const layer_type *get_layer_ptr() const {
            return this->layer_ptr;
        }
        
        const axis_type get_axis() const {
            return this->axis;
        }
        
        const constraint_struct_vector_type &get_constraints() const {
            return this->constraints;
        }
        
        template <typename Enumerator>
        void enumerate_constraint_structs(const Enumerator &enumerator) const {
            bool stop = false;
            for (const constraint_struct_type &constraint_struct : this->constraints) {
                enumerator(constraint_struct, &stop);
                if (stop) {
                    break;
                }
            }
        }
        
        template <typename Enumerator>
        void enumerate_constraint_structs_in_layer(const layer_type *layer_ptr, const Enumerator &enumerator) {
            bool stop = false;
            for (constraint_type *constraint in layer_ptr.constraints) {
                if (stop) {
                    break;
                }
                const DLCLConstraintStruct &constraintStruct = constraint.constraintStruct;
                layer_type *super_layer = layer_ptr.superlayer;
                if (!super_layer) {
                    continue;
                }
                layer_type *identified_layer = [constraint detectSourceLayerInSuperlayer:super_layer];
                if (!identified_layer) {
                    // no layer with given name. Ignore constraint.
                    continue;
                }
                enumerator(constraintStruct, &stop);
            }
        }
        
        void add_constraint(const constraint_struct_type &constraint_struct) {
            axis_type constraint_axis = DLCLConstraintAttributeGetAxis(constraint_struct.attribute);
            if (constraint_axis != this->axis) {
                return;
            }
            this->constraints.push_back(constraint_struct);
        }
        
        const node_ptr_set_type &get_incoming() const {
            return this->incoming;
        }
        
        const node_ptr_set_type &get_outgoing() const {
            return this->outgoing;
        }
        
        bool depends_on(const constraint_layout_node &node) const {
            bool depends = false;
            this->enumerate_constraint_structs([&](const constraint_struct_type &constraint_struct, bool *stop) {
                if (constraint_struct.source_layer != node.layer_ptr) {
                    return;
                }
                node.enumerate_constraint_structs([&](const constraint_struct_type &other_constraint_struct, bool *stop) {
                    axis_type constraint_source_axis = DLCLConstraintAttributeGetAxis(constraint_struct.source_attribute);
                    axis_type other_constraint_axis = DLCLConstraintAttributeGetAxis(other_constraint_struct.attribute);
                    if (constraint_source_axis == other_constraint_axis) {
                        depends = true;
                        return;
                    }
                });
            });
            return depends;
        }
        
        static void add_dependency(constraint_layout_node &node, constraint_layout_node &dependency_node) {
            node.incoming.insert(&dependency_node);
            dependency_node.outgoing.insert(&node);
        }
        
        static void remove_dependency(constraint_layout_node &node, constraint_layout_node &dependency_node) {
            node.incoming.erase(&dependency_node);
            dependency_node.outgoing.erase(&node);
        }
        
    private:
        
        const layer_type *layer_ptr;
        const axis_type axis;
        constraint_struct_vector_type constraints;
        node_ptr_set_type incoming;
        node_ptr_set_type outgoing;
    };
    
    class solver {
		using node_type = dlcl::constraint_layout_node;
        using node_pair_type = node_type::node_pair_type;
		using constraint_type = node_type::constraint_type;
        using constraint_struct_type = node_type::constraint_struct_type;
        using layer_type = node_type::layer_type;
		using frame_type = CGRect;
        using attribute_type = node_type::attribute_type;
        using axis_type = node_type::axis_type;
        using axis_attribute_type = node_type::axis_attribute_type;
		using value_by_axis_attribute_type = std::map<axis_attribute_type, CGFloat>;
		
		typedef std::vector<node_type> node_vector_type;
		typedef std::vector<node_type *> node_ptr_vector_type;
		typedef std::set<node_type *> node_ptr_set_type;
		
		CALayer *root_layer;
		node_vector_type nodes;
		node_ptr_vector_type sorted_nodes;
		
	public:
		
		solver(CALayer *root_layer = nullptr) throw(std::runtime_error) : root_layer(root_layer) {
			this->generate_nodes(root_layer);
			this->add_node_dependencies();
			this->sort_nodes_topologically();
			this->validate_sorted_nodes(); // throws exception on dependency circles
		}
		
		void solve() {
			this->enumerate_sorted_nodes([&](node_type &node, bool *stop) {
				solver::solve_node(node);
			});
		}
		
	private:
		
        template <typename Enumerator>
		static void enumerate_sublayers(CALayer *layer, const Enumerator &enumerator) {
			bool stop = false;
			for (CALayer *sub_layer in layer.sublayers) {
				if (stop) {
					break;
				}
				enumerator(sub_layer, &stop);
			}
		}
        
        template <typename Enumerator>
		void enumerate_nodes(const Enumerator &enumerator) {
			bool stop = false;
			for (auto &node : this->nodes) {
				enumerator(node, &stop);
				if (stop) {
					break;
				}
			}
		}
		
        template <typename Enumerator>
		void enumerate_sorted_nodes(const Enumerator &enumerator) {
			bool stop = false;
			for (auto &node : this->sorted_nodes) {
				enumerator(*node, &stop);
				if (stop) {
					break;
				}
			}
		}
        
        template <typename Enumerator>
        void enumerate_constraint_structs_in_layer(const layer_type *layer, const Enumerator &enumerator) {
			bool stop = false;
			for (constraint_type *constraint in layer.constraints) {
				if (stop) {
					break;
				}
                layer_type *super_layer = layer.superlayer;
				if (!super_layer) {
					continue;
				}
				const layer_type *identified_layer = [constraint detectSourceLayerInSuperlayer:super_layer];
				if (!identified_layer) {
					// no layer with given name. Ignore constraint.
					continue;
				}
				enumerator(constraint.constraintStruct, &stop);
			}
		}
        
		void generate_nodes(CALayer *root_layer) {
			this->nodes.clear();
			this->enumerate_sublayers(root_layer, [&](CALayer *sub_layer, bool *stop) {
                node_pair_type node_pair({constraint_layout_node(sub_layer, DLCLConstraintAxisX), constraint_layout_node(sub_layer, DLCLConstraintAxisY)});
                this->enumerate_constraint_structs_in_layer(sub_layer, [&](const constraint_struct_type &constraint_struct, bool *stop) {
                    DLCLConstraintAxis axis = DLCLConstraintAttributeGetAxis(constraint_struct.attribute);
                    constraint_layout_node &node = (axis == DLCLConstraintAxisX) ? node_pair.first : node_pair.second;
                    node.add_constraint(constraint_struct);
                });
				if (!node_pair.first.get_constraints().empty()) {
					this->nodes.push_back(std::move(node_pair.first));
					// do not touch node_pair.first from now on!
				}
				if (!node_pair.second.get_constraints().empty()) {
					this->nodes.push_back(std::move(node_pair.second));
					// do not touch node_pair.second from now on!
				}
			});
		}
		
		void add_node_dependencies() {
			using nodes_by_layer = std::map<const CALayer *, node_ptr_set_type>;
			nodes_by_layer node_maps_by_axis[] {
				nodes_by_layer(),
				nodes_by_layer()
			};
			this->enumerate_nodes([&](node_type &node, bool *stop) {
				nodes_by_layer &nodes_on_axis = node_maps_by_axis[node.get_axis()];
				nodes_on_axis[node.get_layer_ptr()].insert(&node);
			});
			this->enumerate_nodes([&](node_type &node, bool *stop) {
				node.enumerate_constraint_structs([&](const constraint_struct_type &constraint_struct, bool *stop) {
					CALayer *source_layer = constraint_struct.source_layer;
					if (!source_layer) {
						return;
					}
                    DLCLConstraintAxis axis = DLCLConstraintAttributeGetAxis(constraint_struct.attribute);
					nodes_by_layer &nodes_on_axis = node_maps_by_axis[axis];
					if (!nodes_on_axis.count(source_layer)) {
						return;
					}
					for (auto &source_node_ptr : nodes_on_axis[source_layer]) {
						if (node.depends_on(*source_node_ptr)) {
							node_type::add_dependency(node, *source_node_ptr);
						}
					}
				});
			});
		}
		
		void sort_nodes_topologically() {
			this->sorted_nodes.clear();
			std::queue<node_type *> queue;
			this->enumerate_nodes([&](node_type &node, bool *stop) {
				if (!node.get_incoming().size()) {
					queue.push((node_type *)&node);
				}
			});
			while (!queue.empty()) {
				node_type &node = *queue.front();
				queue.pop();
				this->sorted_nodes.push_back(&node);
				node_ptr_set_type outgoing = node.get_outgoing();
				for (auto &outgoing_node_ptr : outgoing) {
					node_type::remove_dependency(*outgoing_node_ptr, node);
					if (outgoing_node_ptr->get_incoming().empty()) {
						queue.push(outgoing_node_ptr);
					}
				}
			}
		}
		
		void validate_sorted_nodes() throw(std::runtime_error) {
			for (node_type *node_ptr : this->sorted_nodes) {
				if (!node_ptr->get_outgoing().empty() || !node_ptr->get_incoming().empty()) {
					throw std::runtime_error("Circle detected. Constraint dependencies must not form cycles.");
				}
			}
		}
		
		static void solve_node(node_type &node) {
			const CALayer *layer_ptr = node.get_layer_ptr();
			if (!layer_ptr) {
				return;
			}
			value_by_axis_attribute_type source_values;
			int axis_attributes_mask = 0x0;
			node.enumerate_constraint_structs([&](const constraint_struct_type &constraint_struct, bool *stop) {
				attribute_type attribute = constraint_struct.attribute;
                attribute_type source_attribute = constraint_struct.source_attribute;
				axis_attribute_type axis_attribute = DLCLConstraintAttributeGetAxisAttribute(attribute);
				axis_attributes_mask |= (0x1 << (int)axis_attribute);
				frame_type source_layer_frame = constraint_struct.source_layer.frame;
				CGFloat source_attribute_value = get_attribute(source_layer_frame, source_attribute);
				source_values[axis_attribute] = (source_attribute_value * constraint_struct.scale) + constraint_struct.offset;
			});
            layer_ptr.frame = frame_after_setting_attributes(layer_ptr.frame, axis_attributes_mask, node.get_axis(), source_values);
		}
		
		static frame_type frame_after_setting_attributes(frame_type frame, const int &axis_attributes_mask, const axis_type &axis, const value_by_axis_attribute_type &source) {
			CGFloat layer_min_value = (axis == DLCLConstraintAxisX) ? frame.origin.x : frame.origin.y;
			CGFloat layer_size_value = (axis == DLCLConstraintAxisX) ? frame.size.width : frame.size.height;
			if (axis_attributes_mask & (0x1 << DLCLConstraintAxisAttributeMin)) {
				layer_min_value = source.at(DLCLConstraintAxisAttributeMin); // min
				if (axis_attributes_mask & (0x1 << DLCLConstraintAxisAttributeMid)) { // min & mid
					layer_size_value = (source.at(DLCLConstraintAxisAttributeMid) - source.at(DLCLConstraintAxisAttributeMin)) * 2;
				} else if (axis_attributes_mask & (0x1 << DLCLConstraintAxisAttributeMax)) { // min & max
					layer_size_value = (source.at(DLCLConstraintAxisAttributeMax) - source.at(DLCLConstraintAxisAttributeMin));
				} else if (axis_attributes_mask & (0x1 << DLCLConstraintAxisAttributeSize)) { // min & size
					layer_size_value = source.at(DLCLConstraintAxisAttributeSize);
				}
			} else if (axis_attributes_mask & (0x1 << DLCLConstraintAxisAttributeSize)) {
				layer_size_value = source.at(DLCLConstraintAxisAttributeSize); // size
				if (axis_attributes_mask & (0x1 << DLCLConstraintAxisAttributeMid)) { // size & mid
					layer_min_value = source.at(DLCLConstraintAxisAttributeMid) - (source.at(DLCLConstraintAxisAttributeSize) / 2);
				} else if (axis_attributes_mask & (0x1 << DLCLConstraintAxisAttributeMax)) { // size & max
					layer_min_value = source.at(DLCLConstraintAxisAttributeMax) - source.at(DLCLConstraintAxisAttributeSize);
				}
			} else if (axis_attributes_mask & (0x1 << DLCLConstraintAxisAttributeMid)) {
				layer_min_value = source.at(DLCLConstraintAxisAttributeMid) - (layer_size_value / 2); // mid
				if (axis_attributes_mask & (0x1 << DLCLConstraintAxisAttributeMax)) { // mid & max
					layer_size_value = (source.at(DLCLConstraintAxisAttributeMax) - source.at(DLCLConstraintAxisAttributeMid)) * 2;
					layer_min_value = source.at(DLCLConstraintAxisAttributeMax) - layer_size_value;
				}
			} else if (axis_attributes_mask & (0x1 << DLCLConstraintAxisAttributeMax)) {
				layer_min_value = source.at(DLCLConstraintAxisAttributeMax) - layer_size_value; // max
			}
            if (axis == DLCLConstraintAxisX) {
				frame.origin.x = layer_min_value;
			} else {
				frame.origin.y = layer_min_value;
			}
            if (axis == DLCLConstraintAxisX) {
				frame.size.width = layer_size_value;
			} else {
				frame.size.height = layer_size_value;
			}
			return frame;
		}
        
        static CGFloat get_attribute(const frame_type &frame, const attribute_type &attribute) {
			return get_attribute(frame, DLCLConstraintAttributeGetAxis(attribute), DLCLConstraintAttributeGetAxisAttribute(attribute));
		}
		
		static CGFloat get_attribute(const frame_type &frame, const axis_type &axis, const axis_attribute_type &axis_attribute) {
			CGFloat value;
			switch (axis_attribute) {
				case DLCLConstraintAxisAttributeMin:  { value = (axis == DLCLConstraintAxisX) ? CGRectGetMinX(frame)  : CGRectGetMinY(frame);   break; }
				case DLCLConstraintAxisAttributeMid:  { value = (axis == DLCLConstraintAxisX) ? CGRectGetMidX(frame)  : CGRectGetMidY(frame);   break; }
				case DLCLConstraintAxisAttributeMax:  { value = (axis == DLCLConstraintAxisX) ? CGRectGetMaxX(frame)  : CGRectGetMaxY(frame);   break; }
				case DLCLConstraintAxisAttributeSize: { value = (axis == DLCLConstraintAxisX) ? CGRectGetWidth(frame) : CGRectGetHeight(frame); break; }
				default: {
					throw std::runtime_error("Unknown attribute.");
					break;
				}
            }
            return value;
        }
        
	};
    
}

#endif

#if defined(DLCL_USE_CPP_SOLVER)
@interface DLCLConstraintLayoutSolver ()

@property (readwrite, weak, nonatomic) CALayer *layer;

@end

@implementation DLCLConstraintLayoutSolver {
    std::unique_ptr<dlcl::solver> solver;
}
#else
@interface DLCLConstraintLayoutSolver ()

@property (readwrite, weak, nonatomic) CALayer *layer;
@property (readwrite, strong, nonatomic) NSMutableArray *nodes;

@end

@implementation DLCLConstraintLayoutSolver
#endif

- (id)initWithLayer:(CALayer *)layer {
	self = [self init];
	if (self) {
		self.layer = layer;
        
        BOOL isCircleFree = YES;
#if defined(DLCL_USE_CPP_SOLVER)
        try {
            std::unique_ptr<dlcl::solver> unique_solver(new dlcl::solver(layer));
            self->solver = std::move(unique_solver);
        } catch (const std::runtime_error &exception) {
            isCircleFree = NO;
        }
#else
        self.nodes = [NSMutableArray array];
		[self generateNodesForLayer:self.layer];
		[self addNodeDependencies];
		[self sortNodesTopologically];
		isCircleFree = [self validateSortedNodes];
#endif
        if (!isCircleFree) {
            [NSException raise:@"DLCLConstraintLayoutSolverFoundCircularDependenciesException"
                        format:@"Circle detected. Constraint dependencies must not form cycles."];
        }
	}
	return self;
}

+ (instancetype)solverWithLayer:(CALayer *)layer {
	return [[self alloc] initWithLayer:layer];
}

- (void)solveLayout {
#if defined(DLCL_USE_CPP_SOLVER)
    self->solver->solve();
#else
    CALayer *superlayer = self.layer;
	for (DLCLConstraintLayoutNode *node in self.nodes) {
		[self solveNode:node inSuperlayer:superlayer];
	}
#endif
}

#if !defined(DLCL_USE_CPP_SOLVER)

- (void)generateNodesForLayer:(CALayer *)layer {
	[self.nodes removeAllObjects];
	for (CALayer *sublayer in layer.sublayers) {
		DLCLConstraintLayoutNode *axisNodes[] = {
			[DLCLConstraintLayoutNode nodeWithAxis:DLCLConstraintAxisX forLayer:sublayer],
			[DLCLConstraintLayoutNode nodeWithAxis:DLCLConstraintAxisY forLayer:sublayer]
		};
		for (DLCLConstraint *constraint in sublayer.constraints) {
			DLCLConstraintAxis axis = DLCLConstraintAttributeGetAxis(constraint.attribute);
			[axisNodes[axis] addConstraint:constraint];
		}
		if ([axisNodes[DLCLConstraintAxisX].constraints count]) {
			[self.nodes addObject:axisNodes[DLCLConstraintAxisX]];
		}
		if ([axisNodes[DLCLConstraintAxisY].constraints count]) {
			[self.nodes addObject:axisNodes[DLCLConstraintAxisY]];
		}
	}
}

- (void)addNodeDependencies {
	NSMutableDictionary *nodesByAxis[] = {
		[NSMutableDictionary dictionary],
		[NSMutableDictionary dictionary]
	};
	// Create lookup dictionaries:
	for (DLCLConstraintLayoutNode *node in self.nodes) {
		NSMutableDictionary *nodesByLayer = nodesByAxis[node.axis];
		NSValue *pointerValue = [NSValue valueWithPointer:(void *)node.layer];
		NSMutableSet *nodes = nodesByLayer[pointerValue];
		if (!nodes) {
			nodes = [NSMutableSet set];
			nodesByLayer[pointerValue] = nodes;
		}
		[nodes addObject:node];
	}
	for (DLCLConstraintLayoutNode *node in self.nodes) {
		CALayer *superlayer = node.layer.superlayer;
		for (DLCLConstraint *constraint in node.constraints) {
			CALayer *sourceLayer = [constraint detectSourceLayerInSuperlayer:superlayer];
			if (!sourceLayer) {
				continue;
			}
            DLCLConstraintAxis sourceAxis = DLCLConstraintAttributeGetAxis(constraint.sourceAttribute);
			NSMutableDictionary *nodesByLayer = nodesByAxis[sourceAxis];
			NSMutableArray *sourceNodes = [nodesByLayer objectForKey:[NSValue valueWithPointer:(void *)sourceLayer]];
			for (DLCLConstraintLayoutNode *sourceNode in sourceNodes) {
				if ([node hasDependencyTo:sourceNode]) {
					[node addDependencyTo:sourceNode];
				}
			}
		}
	}
}

- (void)sortNodesTopologically {
	NSArray *nodes = [NSArray arrayWithArray:self.nodes];
	[self.nodes removeAllObjects];
	NSMutableArray *queue = [NSMutableArray array];
	for (DLCLConstraintLayoutNode *node in nodes) {
		if (![node.incoming count]) {
			[queue addObject:node];
		}
	}
	while ([queue count]) {
		DLCLConstraintLayoutNode *node = queue[0];
		[queue removeObjectAtIndex:0];
		[self.nodes addObject:node];
		for (DLCLConstraintLayoutNode *outgoingNode in [NSSet setWithSet:node.outgoing]) {
			[outgoingNode removeDependencyTo:node];
			if (![outgoingNode.incoming count]) {
				[queue addObject:outgoingNode];
			}
		}
	}
}

- (BOOL)validateSortedNodes {
	for (DLCLConstraintLayoutNode *node in self.nodes) {
		if ([node.outgoing count] || [node.incoming count]) {
			return NO;
		}
	}
	return YES;
}

- (void)solveNode:(DLCLConstraintLayoutNode *)node inSuperlayer:(CALayer *)superlayer {
	CALayer *layer = node.layer;
	if (!layer) {
		return;
	}
	CGRect frame = layer.frame;
	NSMutableDictionary *sourceValuesByAxisAttribute = [NSMutableDictionary dictionary];
	int axisAttributesMask = 0x0;
	for (DLCLConstraint *constraint in node.constraints) {
        DLCLConstraintAttribute attribute = constraint.attribute;
        DLCLConstraintAttribute sourceAttribute = constraint.sourceAttribute;
		DLCLConstraintAxisAttribute axisAttribute = DLCLConstraintAttributeGetAxisAttribute(attribute);
		CALayer *sourceLayer = constraint.sourceLayer;
		if (!sourceLayer) {
			continue;
		}
		axisAttributesMask |= (0x1 << (int)axisAttribute);
		CGRect sourceFrame = sourceLayer.frame;
		typedef CGFloat DLCLRectFunction(CGRect rect);
		DLCLRectFunction *rectFunctions[] = {
			&CGRectGetMinX, &CGRectGetMidX, &CGRectGetMaxX, &CGRectGetWidth,
			&CGRectGetMinY, &CGRectGetMidY, &CGRectGetMaxY, &CGRectGetHeight
		};
		CGFloat sourceAttributeValue = rectFunctions[sourceAttribute](sourceFrame);
		sourceValuesByAxisAttribute[@((int)axisAttribute)] = @((sourceAttributeValue * constraint.scale) + constraint.offset);
	}
	layer.frame = [[self class] frame:(CGRect)frame afterSettingAttributeValues:sourceValuesByAxisAttribute onAxis:node.axis forMask:axisAttributesMask];
}

+ (CGRect)frame:(CGRect)frame afterSettingAttributeValues:(NSDictionary *)attributeValues onAxis:(DLCLConstraintAxis)axis forMask:(int)axisAttributesMask {
	NSNumber *minKey = @((int)DLCLConstraintAxisAttributeMin);
	NSNumber *midKey = @((int)DLCLConstraintAxisAttributeMid);
	NSNumber *maxKey = @((int)DLCLConstraintAxisAttributeMax);
	NSNumber *sizeKey = @((int)DLCLConstraintAxisAttributeSize);
	CGFloat minValue = (axis == DLCLConstraintAxisX) ? CGRectGetMinX(frame) : CGRectGetMinY(frame);
	CGFloat sizeValue = (axis == DLCLConstraintAxisX) ? CGRectGetWidth(frame) : CGRectGetHeight(frame);
	
	if (axisAttributesMask & (0x1 << DLCLConstraintAxisAttributeMin)) {
		minValue = [attributeValues[minKey] doubleValue]; // min
		if (axisAttributesMask & (0x1 << DLCLConstraintAxisAttributeMid)) { // min & mid
			sizeValue = ([attributeValues[midKey] doubleValue] - minValue) * 2;
		} else if (axisAttributesMask & (0x1 << DLCLConstraintAxisAttributeMax)) { // min & max
			sizeValue = ([attributeValues[maxKey] doubleValue] - minValue);
		} else if (axisAttributesMask & (0x1 << DLCLConstraintAxisAttributeSize)) { // min & size
			sizeValue = [attributeValues[sizeKey] doubleValue];
		}
	} else if (axisAttributesMask & (0x1 << DLCLConstraintAxisAttributeSize)) {
		sizeValue = [attributeValues[sizeKey] doubleValue]; // size
		if (axisAttributesMask & (0x1 << DLCLConstraintAxisAttributeMid)) { // size & mid
			minValue = [attributeValues[midKey] doubleValue] - (sizeValue / 2);
		} else if (axisAttributesMask & (0x1 << DLCLConstraintAxisAttributeMax)) { // size & max
			minValue = [attributeValues[maxKey] doubleValue] - sizeValue;
		}
	} else if (axisAttributesMask & (0x1 << DLCLConstraintAxisAttributeMid)) {
		minValue = [attributeValues[midKey] doubleValue] - (sizeValue / 2); // mid
		if (axisAttributesMask & (0x1 << DLCLConstraintAxisAttributeMax)) { // mid & max
			sizeValue = ([attributeValues[maxKey] doubleValue] - [attributeValues[midKey] doubleValue]) * 2;
			minValue = [attributeValues[maxKey] doubleValue] - sizeValue;
		}
	} else if (axisAttributesMask & (0x1 << DLCLConstraintAxisAttributeMax)) {
		minValue = [attributeValues[maxKey] doubleValue] - sizeValue; // max
	}
	if (axis == DLCLConstraintAxisX) {
		frame.origin.x = minValue;
		frame.size.width = sizeValue;
	} else {
		frame.origin.y = minValue;
		frame.size.height = sizeValue;
	}
	return frame;
}

#endif

@end
