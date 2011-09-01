﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using QuickFix.Fields;
using System.Reflection;

namespace QuickFix
{
    public abstract class MessageCracker
    {
        private Dictionary<Type, MethodInfo> _handlerMethods = new Dictionary<Type, MethodInfo>();

        public MessageCracker()
        {
            initialize(this);
        }

        private void initialize(Object messageHandler)
        {
            Type handlerType = messageHandler.GetType();

            MethodInfo[] methods = handlerType.GetMethods();
            foreach (MethodInfo m in methods)
            {
                if (IsHandlerMethod(m))
                {
                    _handlerMethods[m.GetParameters()[0].ParameterType] = m;
                }
            }
        }


        static public bool IsHandlerMethod(MethodInfo m)
        {
            return (m.IsPublic == true
                && m.Name.Equals("OnMessage")
                && m.GetParameters().Length == 2
                && m.GetParameters()[0].ParameterType.IsSubclassOf(typeof(QuickFix.Message))
                && typeof(QuickFix.SessionID).IsAssignableFrom(m.GetParameters()[1].ParameterType)
                && m.ReturnType == typeof(void));
        }



        public void Crack(Message message, SessionID sessionID)
        {
            Type messageType = message.GetType();
            MethodInfo handler = null;

            if (_handlerMethods.TryGetValue(messageType, out handler))
                handler.Invoke(this, new object[] { message, sessionID });
            else
                throw new UnsupportedMessageType();
        }
    }
}
