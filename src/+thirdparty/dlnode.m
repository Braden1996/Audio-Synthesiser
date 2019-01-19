% Credit:
% http://uk.mathworks.com/help/matlab/matlab_oop/example--implementing-linked-lists.html
classdef dlnode < handle
   % dlnode A class to represent a doubly-linked node.
   % Link multiple dlnode objects together to create linked lists.
   properties
      Data
   end
   properties(SetAccess = private)
      Next
      Prev
   end
   
   methods
      function node = dlnode(Data)
         % Construct a dlnode object
         if nargin > 0
            node.Data = Data;
         end
         
          node.Next = node.empty;
          node.Prev = node.empty;
      end
      
      function insertAfter(newNode, nodeBefore)
         % Insert newNode after nodeBefore.
         removeNode(newNode);
         newNode.Next = nodeBefore.Next;
         newNode.Prev = nodeBefore;
         if ~isempty(nodeBefore.Next)
            nodeBefore.Next.Prev = newNode;
         end
         nodeBefore.Next = newNode;
      end
      
      function insertBefore(newNode, nodeAfter)
         % Insert newNode before nodeAfter.
         removeNode(newNode);
         newNode.Next = nodeAfter;
         newNode.Prev = nodeAfter.Prev;
         if ~isempty(nodeAfter.Prev)
            nodeAfter.Prev.Next = newNode;
         end
         nodeAfter.Prev = newNode;
      end
      
      function removeNode(node)
         % Remove a node from a linked list.
         if ~isscalar(node)
            error('Input must be scalar')
         end
         prevNode = node.Prev;
         nextNode = node.Next;
         if ~isempty(prevNode)
            prevNode.Next = nextNode;
         end
         if ~isempty(nextNode)
            nextNode.Prev = prevNode;
         end
         node.Next = node.empty;
         node.Prev = node.empty;
      end
      
      function clearList(node)
         % Clear the list before
         % clearing list variable
         prev = node.Prev;
         next = node.Next;
         removeNode(node)
         while ~isempty(next)
            node = next;
            next = node.Next;
            removeNode(node);
         end
         while ~isempty(prev)
            node = prev;
            prev = node.Prev;
            removeNode(node)
         end
      end
   end
   
   methods (Access = private)
      function delete(node)
         clearList(node)
      end
   end
end