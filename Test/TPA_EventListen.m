classdef TPA_EventListen < event.EventData
    
    properties (SetAccess = private)
        Size
        Price
        Time
    end         
    
    methods
        
        function[obj] = TPA_EventListen(size,price)             
            obj.Size  = size;
            obj.Price = price;
            obj.Time  = now;
        end
        
        function[out] = char(obj)             
            out = sprintf('Trade: %f at %f',obj.Size,obj.Price);
        end
    
    end   
    
end